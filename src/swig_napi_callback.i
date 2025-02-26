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
 */
%fragment("remove_void", "header") %{
template <class T> struct remove_void { using type = T; };
template <> struct remove_void<void> { using type = int; };
%}

%fragment("SWIG_NAPI_Callback", "header", fragment="<memory>", fragment="remove_void") %{
  #include <thread>
  #include <condition_variable>
  #include <exception>

  // A JS trampoline is an std::function with a custom destructor
  // implemented a custom deleter of a std::unique_ptr.
  // It can be kept on the C++ side, can be called and destroyed both
  // from the JS thread (sync) and the background threads (async).
  // It must be constructed on the JS thread.
  // It does not support reentrancy, the C++ code must
  // make multiple parallel calls. The object is trivially
  // copy-constructible but it will always keep the same V8 context
  // which will be destroyed when the last copy is destroyed.
  //
  // Sync mode sequence, everything runs in the JS thread:
  //   * The lambda is constructed from JS context
  //   * JS runs and calls the C++ code which needs the callback
  //   * C++ calls operator() which calls do_call to enter JS, then
  //     processes the returned value, then lifts the barrier
  //   * The barrier is already open when the outer lambda reaches the end
  //
  // Async mode sequence:
  //   * [JS thread] The lambda is constructed from JS context
  //   * [JS thread] JS runs and calls the C++ code which needs the callback
  //   * [Background thread] C++ calls operator() which schedules
  //     do_call via TSFN to run on the main thread and stops on the barrier
  //   * [JS thread] do_call runs, calls JS and handles the returned value
  //     If the JS callback is not async, it unblocks the barrier
  //     If the JS callback is async, do_call schedules the two innermost
  //     lambdas to run on .then() and on .catch()
  //     The innermost lambdas process the values and unblock the outer
  //     lambda
  //   * [Background thread] C++ is unblocked, everything else must have
  //     finished running and destructing, the outer lambda that contains
  //     the local variables is destroyed
  //
  template <typename RET, typename ...ARGS>
  std::function<RET(ARGS...)> SWIG_NAPI_Callback(
    Napi::Value js_callback,
    // These perform argument and return value conversions and
    // can be called only on the JS thread
    std::function<void(Napi::Env, std::vector<napi_value> &, ARGS...)> tmaps_in,
    std::function<RET(Napi::Env, Napi::Value)> tmap_out,
    Napi::Value this_value
  ) {
    Napi::Env env{js_callback.Env()};
    if (!js_callback.IsFunction()) throw Napi::Error::New(js_callback.Env(), "Passed argument is not a function");

    // The V8 context can be created and destroyed only
    // in the JS thread
    struct NAPIContext {
      std::thread::id main_thread_id;
      // Used when calling from a background thread
      Napi::ThreadSafeFunction tsfn;
      // Used when calling from the JS thread
      Napi::Reference<Napi::Function> jsfn_ref;
      // The this value inside the JS callback
      Napi::Reference<Napi::Value> this_value_ref;
    };

    auto *napi_context = new NAPIContext;
    napi_context->main_thread_id = std::this_thread::get_id();
    napi_context->tsfn = Napi::ThreadSafeFunction::New(env,
      js_callback.As<Napi::Function>(),
      Napi::Object::New(env),
      "SWIG_callback_task",
      0,
      1
    );
    napi_context->jsfn_ref = Napi::Persistent(js_callback.As<Napi::Function>());
    napi_context->this_value_ref = Napi::Persistent(this_value);
    //printf("create context %p\n", napi_context);

    // The bottom half of the deleter that runs on the main thread
    // It has a TSFN call signature
    static const auto destroy_context_bottom_half = [](Napi::Env, Napi::Function, NAPIContext *context) {
      //printf("async deletion bottom half %p\n", context);
      context->tsfn.Release();
      delete context;
    };

    // The custom unique_ptr deleter
    static const auto destroy_context = [](NAPIContext *context) {
      if (std::this_thread::get_id() == context->main_thread_id) {
        //printf("sync deletion %p\n", context);
        // Sync deletion - actually delete
        context->tsfn.Release();
        delete context;
      } else {
        //printf("async deletion %p\n", context);
        // Async deletion - reschedule on the JS thread
        context->tsfn.BlockingCall(context, destroy_context_bottom_half);
      }
    };

    // This is the function that will be returned to the C++ code
    return [napi_context, tmaps_in, tmap_out](ARGS&&... args) -> RET {
      // This is what allows to have a custom destructor for the lambda which
      // is otherwise trivially copy-constructible
      std::unique_ptr<NAPIContext, decltype(destroy_context)> context{napi_context, destroy_context};

      // Here we are called by the C++ code - we might be in a the main thread (synchronous call)
      // or a background thread (asynchronous call).
      auto worker_thread_id = std::this_thread::get_id();
      typename remove_void<RET>::type c_ret;
      std::string error_msg;
      std::mutex m;
      std::condition_variable cv;
      bool ready = false;
      bool error = false;

      // This is the actual trampoline that allows call into JS
      auto do_call = [&c_ret, &error_msg, &m, &cv, &ready, &error,
                      context = context.get(), worker_thread_id,
                      tmaps_in, tmap_out,
                      &args...] (Napi::Env env, Napi::Function js_callback) {
        {
          // Here we are back in the main V8 thread, potentially from an async context
          Napi::HandleScope store{env};

          // Convert the C++ arguments to JS
          std::vector<napi_value> js_args(sizeof...(args));
          tmaps_in(env, js_args, args...);

          // Call the JS callback
          try {
            Napi::Value js_ret = js_callback.Call(context->this_value_ref.Value(), js_args);

            // You don't need this part if you are not going to support async functions
  #ifdef ASYNC_CALLBACK_SUPPORT
            // Handle the Promise in case the function was async
            if (js_ret.IsPromise()) {
              if (context->main_thread_id == worker_thread_id) {
                throw std::runtime_error{"Can't resolve a Promise when called synchronously"};
              }
              napi_value on_resolve = Napi::Function::New(env, [env, tmap_out, &c_ret, &error_msg, &m, &cv, &ready, &error]
                  (const Napi::CallbackInfo &info) {
                  // Handle the JS return value
                  try {
                    if constexpr (!std::is_void<RET>::value)
                      c_ret = tmap_out(env, info[0]);
                    else {
                      (void)env;
                      (void)c_ret;
                    }
                  } catch (const std::exception &e) {
                    error = true;
                    error_msg = e.what();
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
              napi_value on_reject = Napi::Function::New(env, [&error_msg, &m, &cv, &ready, &error]
                  (const Napi::CallbackInfo &info) {
                  // Handle exceptions
                  error = true;
                  error_msg = info[0].ToString();

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
            if constexpr (!std::is_void<RET>::value)
              c_ret = tmap_out(env, js_ret);
          } catch (const std::exception &err) {
            // Handle exceptions
            error = true;
            error_msg = err.what();
          }
        }

        // Unblock the C++ thread
        std::lock_guard<std::mutex> lock{m};
        ready = true;
        cv.notify_one();
      };

      // Are we in the thread pool background thread (V8 is not accessible) or not?
      // (this is what allows this typemap to work in both sync and async mode)
      if (worker_thread_id == context->main_thread_id) {
        // Synchronous call
        Napi::Function js_cb = context->jsfn_ref.Value();
        do_call(js_cb.Env(), js_cb);
      } else {
        // Asynchronous call
        context->tsfn.BlockingCall(do_call);
      }

      // This is a barrier
      std::unique_lock<std::mutex> lock{m};
      cv.wait(lock, [&ready]{ return ready; });

      if (error) throw std::runtime_error{error_msg};
      if constexpr (!std::is_void<RET>::value)
        return c_ret;
      else
        return;
    };
  };
%}
