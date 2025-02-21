/**
 * This is an implementation of a generic std::function factory that can produce
 * C++ functions from JS functions.
 *
 * It will be included in the standard library in SWIG JSE in a near future.
 *
 * The C++ functions support being called both synchronously and asynchronously.
 *
 * When called asynchronously, they support automatically resolving Promises returned from
 * JavaScript async callbacks.
 *
 * Note that this implementation returns an std::function with a captured shared_ptr
 * that handles the release of the JS resources once the last copy of the std::function is
 * destroyed. This means that you should take extra care when passing any shared_ptr as arguments
 * because this can lead to a dependency cycle between shared_ptr that can never be freed.
 */
%fragment("SWIG_NAPI_Callback", "header") %{
  #include <thread>
  #include <condition_variable>
  #include <exception>

  template <typename RET, typename ...ARGS>
  std::function<RET(ARGS...)> SWIG_NAPI_Callback(
      Napi::Value js_callback,
      std::function<void(Napi::Env, std::vector<napi_value> &, ARGS...)> tmaps_in,
      std::function<RET(Napi::Env, Napi::Value)> tmap_out
    ) {
      return SWIG_NAPI_Callback(js_callback, tmaps_in, tmap_out,
        [](Napi::Env env, Napi::Function js_callback, std::vector<napi_value> &js_args){
          return js_callback.Call(env.Undefined(), js_args);
      });
    }

  template <typename RET, typename ...ARGS>
  std::function<RET(ARGS...)> SWIG_NAPI_Callback(
      Napi::Value js_callback,
      std::function<void(Napi::Env, std::vector<napi_value> &, ARGS...)> tmaps_in,
      std::function<RET(Napi::Env, Napi::Value)> tmap_out,
      std::function<Napi::Value(Napi::Env, Napi::Function, const std::vector<napi_value> &)> call
    ) {
    Napi::Env env{js_callback.Env()};
    std::shared_ptr<Napi::ThreadSafeFunction> tsfn{new Napi::ThreadSafeFunction(Napi::ThreadSafeFunction::New(env,
      js_callback.As<Napi::Function>(),
      Napi::Object::New(env),
      "SWIG_callback_task",
      0,
      1
    )), [](Napi::ThreadSafeFunction *t){
      t->Release();
      delete t;
    }};

    // Here we are in the main V8 thread
    auto main_thread_id = std::this_thread::get_id();

    // $1 is what we pass to the C++ function -> it is a C++ wrapper
    // around the JS callback
    return [tsfn, js_callback, main_thread_id, tmaps_in, tmap_out, call](ARGS &&...args) -> RET {
      // Here we are called by the C++ code - we might be in a the main thread (synchronous call)
      // or a background thread (asynchronous call)
      auto worker_thread_id = std::this_thread::get_id();
      RET c_ret;
      std::mutex m;
      std::condition_variable cv;
      bool ready = false;
      bool error = false;

      // This is the actual trampoline that allows call into JS
      auto do_call = [&c_ret, &m, &cv, &ready, &error, tsfn, main_thread_id, worker_thread_id,
        tmaps_in, tmap_out, call, &args...]
        (Napi::Env env, Napi::Function js_fn) {
        // Here we are back in the main V8 thread, potentially from an async context
        Napi::HandleScope store{env};

        // Convert the C++ arguments to JS
        // ($typemap with arguments is currently an undocumented
        // but very useful SWIG feature that is not specific to SWIG JSE)
        std::vector<napi_value> js_args{sizeof...(args)};
        tmaps_in(env, js_args, args...);

        // Call the JS callback
        try {
          Napi::Value js_ret = call(env, js_fn, js_args);

          // You don't need this part if you are not going to support async functions
#ifdef ASYNC_CALLBACK_SUPPORT
          // Handle the Promise in case the function was async
          if (js_ret.IsPromise()) {
            if (main_thread_id == worker_thread_id) {
              throw std::runtime_error{"Can't resolve a Promise when called synchronously"};
            }
            napi_value on_resolve = Napi::Function::New(env, [env, tmap_out, &c_ret, &m, &cv, &ready, &error]
                (const Napi::CallbackInfo &info) {
                Napi::HandleScope store{env};
                // Handle the JS return value
                try {
                  c_ret = tmap_out(env, info[0]);
                } catch (const std::exception &e) {
                  error = true;
                  c_ret = e.what();
                }

                // Unblock the C++ thread
                // This is very tricky and it is not the officially recommended
                // C++ locking sequence. We are running in a lambda inside the
                // main lambda and as soon as we unblock it, it can potentially
                // exit and start calling the destructors to the local variables
                // on the stack this lambda references - which means that this
                // lambda will cease to exist, leading to very hard to debug
                // crashes. Keep the mutex until the last possible moment.
                std::lock_guard<std::mutex> lock{m};
                ready = true;
                cv.notify_one();
              });
            napi_value on_reject = Napi::Function::New(env, [env, &c_ret, &m, &cv, &ready, &error]
                (const Napi::CallbackInfo &info) {
                Napi::HandleScope store{env};
                // Handle exceptions
                error = true;
                c_ret = info[0].ToString();

                // Unblock the C++ thread
                std::lock_guard<std::mutex> lock{m};
                ready = true;
                cv.notify_one();
              });
            js_ret.ToObject().Get("then").As<Napi::Function>().Call(js_ret, 1, &on_resolve);
            js_ret.ToObject().Get("catch").As<Napi::Function>().Call(js_ret, 1, &on_reject);
            return;
          }
#endif

          // Handle the JS return value
          c_ret = tmap_out(env, js_ret);
        } catch (const std::exception &err) {
          // Handle exceptions
          error = true;
          c_ret = err.what();
        }

        // Unblock the C++ thread
        std::lock_guard<std::mutex> lock{m};
        ready = true;
        cv.notify_one();
      };

      // Are we in the thread pool background thread (V8 is not accessible) or not?
      // (this is what allows this typemap to work in both sync and async mode)
      if (worker_thread_id == main_thread_id) {
        // Synchronous call
        // (the js_callback Local reference is still valid -> it is on the stack)
        do_call(js_callback.Env(), js_callback.As<Napi::Function>());
      } else {
        // Asynchronous call
        // (js_callback is now a dangling Local reference)
        tsfn->BlockingCall(do_call);
      }

      // This is a barrier
      std::unique_lock<std::mutex> lock{m};
      cv.wait(lock, [&ready]{ return ready; });

      if (error) throw std::runtime_error{c_ret};
      return c_ret;
    };
  }
%}
