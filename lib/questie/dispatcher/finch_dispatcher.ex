if Code.ensure_loaded?(Finch) do
  defmodule Questie.FinchDispatcher do
    alias Questie.Request

    defmacro __using__(conf \\ []) do
      {name, opts} = Keyword.pop(conf, :name)

      if nil == name do
        raise ArgumentError, message: "the :name option is required when using #{__MODULE__}"
      end

      quote do
        @finch_name unquote(name)
        @default_finch_opts unquote(opts)

        alias Questie.Request

        def dispatch(%Request{} = req) do
          unquote(__MODULE__).dispatch(req, @finch_name, @default_finch_opts)
        end
      end
    end

    def dispatch(req) do
      raise "you must use Questie.FinchDispatcher in your own module to be used as a dispatcher"
    end

    def dispatch(%Request{} = req, name, default_opts) do
      %{method: method, headers: headers, body: body, dispatcher_opts: opts} = req
      url = Questie.Request.url_to_string(req)
      freq = Finch.build(method, url, headers, body)
      opts = Keyword.merge(default_opts, opts)
      Finch.request(freq, name, opts)
    end
  end

  defimpl Questie.Response.Adapter, for: Finch.Response do
    def get_status(response) do
      response.status
    end

    def get_headers(response) do
      response.headers
    end

    def get_body(response) do
      response.body
    end

    def put_body(response, body) do
      %{response | body: body}
    end
  end
end
