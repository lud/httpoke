defmodule Questie.HttpbinSuite do
  use ExUnit.CaseTemplate

  using do
    #
    quote location: :keep do
      #
      alias Questie.HttpbinSuite

      @remote "http://127.0.0.1:4444/"

      def _request(req, opts \\ [])

      def _request(%{opts: opts} = req, overrides) do
        _request(opts, overrides)
      end

      def _request(%Questie.Request{} = req, overrides) do
        req
        |> Questie.merge_opts(url: @remote)
        |> Questie.merge_opts(overrides)
      end

      def _request(opts, overrides) when is_list(opts) do
        opts
        |> Questie.request()
        |> _request(overrides)
      end

      def _dispatch(req_or_opts, overrides \\ [])

      def _dispatch(req_or_opts, overrides) do
        req_or_opts
        |> _request(overrides)
        |> Questie.dispatch()
      end

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
end
