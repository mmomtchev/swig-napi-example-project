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
 * Note that this implementation deletes the C++ reference after the function
 * called, if you plan to keep this reference in C++, you will need to remove
 * this part and implement some kind of deallocation yourself. In this case you will
 * probably want to return some kind of functor object that will contain the JS
 * references in it so that you can delete them from the C++ code.
 */
%fragment("SWIG_NAPI_Callback", "header") %{
  #include <thread>
  #include <condition_variable>
  #include <exception>
  #define ASYNC_CALLBACK_SUPPORT

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
    Napi::ThreadSafeFunction *tsfn;
    Napi::FunctionReference *syncfn;

    tsfn = new Napi::ThreadSafeFunction(Napi::ThreadSafeFunction::New(env,
      js_callback.As<Napi::Function>(),
      Napi::Object::New(env),
      "SWIG_callback_task",
      0,
      1
    ));
    syncfn = new Napi::FunctionReference(Napi::Persistent(js_callback.As<Napi::Function>()));
    // Here we are in the main V8 thread
    auto main_thread_id = std::this_thread::get_id();

    // $1 is what we pass to the C++ function -> it is a C++ wrapper
    // around the JS callback
    return [tsfn, syncfn, main_thread_id, tmaps_in, tmap_out, call](ARGS ...args) -> RET {
      // Here we are called by the C++ code - we might be in a the main thread (synchronous call)
      // or a background thread (asynchronous call)
      auto worker_thread_id = std::this_thread::get_id();
      std::string c_ret;
      std::mutex m;
      std::condition_variable cv;
      bool ready = false;
      bool error = false;

      // This is the actual trampoline that allows call into JS
      auto do_call = [&c_ret, &m, &cv, &ready, &error, syncfn, tsfn, main_thread_id, worker_thread_id,
        tmaps_in, tmap_out, call, &args...]
        (Napi::Env env, Napi::Function js_fn) {
        // Here we are back in the main V8 thread

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
                // Handle the JS return value
                try {
                  c_ret = tmap_out(env, info[0]);
                } catch (const std::exception &e) {
                  error = true;
                  c_ret = e.what();
                }

                // Unblock the C++ thread
                std::unique_lock<std::mutex> lock{m};
                ready = true;
                lock.unlock();
                cv.notify_one();
              });
            napi_value on_reject = Napi::Function::New(env, [&c_ret, &m, &cv, &ready, &error]
                (const Napi::CallbackInfo &info) {
                // Handle exceptions
                error = true;
                c_ret = info[0].ToString();

                // Unblock the C++ thread
                std::unique_lock<std::mutex> lock{m};
                ready = true;
                lock.unlock();
                cv.notify_one();
              });
            js_ret.ToObject().Get("then").As<Napi::Function>().Call(js_ret, 1, &on_resolve);
            js_ret.ToObject().Get("catch").As<Napi::Function>().Call(js_ret, 1, &on_reject);

            // Don't do this if you plan to keep the function reference around in C++
            tsfn->Release();
            delete tsfn;
            delete syncfn;
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
        std::unique_lock<std::mutex> lock{m};
        ready = true;
        lock.unlock();
        cv.notify_one();
        
        // Don't do this if you plan to keep the function reference around in C++
        tsfn->Release();
        delete tsfn;
        delete syncfn;
      };

      // Are we in the thread pool background thread (V8 is not accessible) or not?
      // (this is what allows this typemap to work in both sync and async mode)
      if (worker_thread_id == main_thread_id) {
        // Synchronous call
        do_call(syncfn->Env(), syncfn->Value());
      } else {
        // Asynchronous call
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
