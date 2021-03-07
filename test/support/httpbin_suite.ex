defmodule Questie.HttpbinSuite do
  use ExUnit.CaseTemplate

  using do
    quote location: :keep do
      @remote "http://127.0.0.1:4444/"
      # @remote "https://4da084a0798d.ngrok.io/"

      import Questie.HttpbinSuite, only: :macros

      defp _request(req, opts \\ [])

      defp _request(%Questie.Request{} = req, overrides) do
        Questie.merge_opts(req, overrides)
      end

      defp _request(%{opts: opts} = req, overrides) do
        _request(opts, overrides)
      end

      defp _request(opts, overrides) when is_list(opts) do
        opts
        |> Keyword.put_new(:url, @remote)
        |> Questie.request()
        |> _request(overrides)
      end

      defp _dispatch(req_or_opts, overrides \\ [])

      defp _dispatch(req_or_opts, overrides) do
        req_or_opts
        |> _request(overrides)
        |> Questie.dispatch()
      end
    end
  end

  defmacro run_suite(:core) do
    quote location: :keep do
      test "expect status code", ctx do
        assert {:ok, response} = _dispatch(ctx, method: :get, path: "/get")

        assert 200 = Questie.get_status(response)
        assert {:ok, 200} = Questie.expect_status(response, 200)
        assert {:ok, 200} = Questie.expect_status(response, 100..1000)

        assert {:error, {Questie.Response, :bad_status, _}} =
                 Questie.expect_status(response, 400..499)
      end

      test "check http verbs", ctx do
        base = _request(ctx)

        for verb <- ~w(delete get patch post put)a do
          assert {:ok, response} = _dispatch(base, method: verb, path: "/#{verb}")
          assert {:ok, 200} = Questie.expect_status(response, 200)
        end
      end

      test "authorization", ctx do
        base = _request(ctx)

        # -- Basic ------------------------------------------------------------

        username = "SomeUser"
        password = "SomePassword"

        assert {:ok, response} =
                 _dispatch(ctx,
                   method: :get,
                   basic_auth: {username, password},
                   path: "/basic-auth/#{username}/#{password}"
                 )

        assert 200 = Questie.get_status(response)

        assert {:ok, bad_res} =
                 _dispatch(ctx,
                   method: :get,
                   basic_auth: {"bad_name", "bad_password"},
                   path: "/basic-auth/#{username}/#{password}"
                 )

        assert 401 = Questie.get_status(bad_res)

        # hidden should be the same but it returns 404 on failure

        assert {:ok, response} =
                 _dispatch(ctx,
                   method: :get,
                   basic_auth: {username, password},
                   path: "/hidden-basic-auth/#{username}/#{password}"
                 )

        assert 200 = Questie.get_status(response)

        assert {:ok, bad_res} =
                 _dispatch(ctx,
                   method: :get,
                   basic_auth: {"bad_name", "bad_password"},
                   path: "/hidden-basic-auth/#{username}/#{password}"
                 )

        assert 404 = Questie.get_status(bad_res)

        # -- Bearer -----------------------------------------------------------

        token = "7db53f49b48f55fa2765a61544879676.super-secret.token"

        assert {:ok, response} =
                 ctx
                 |> _request(path: "/bearer", method: :get)
                 |> Questie.bearer_token("any token will work")
                 |> _dispatch()

        assert 200 = Questie.get_status(response)
      end
    end
  end

  defmacro run_suite(:redirects) do
    quote location: :keep do
      test "redirects", ctx do
        # We will validate that redirects are not followed
        assert {:ok, response} =
                 _request(ctx, method: :get, path: "/redirect-to")
                 |> Questie.merge_params(url: "/get", status_code: 301)
                 |> _dispatch

        assert 301 = Questie.get_status(response)

        assert "/get" == Questie.get_header(response, "Location")
      end
    end
  end
end
