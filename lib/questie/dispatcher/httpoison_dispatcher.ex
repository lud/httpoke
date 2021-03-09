if Code.ensure_loaded?(HTTPoison) do
  defmodule Questie.HTTPoisonDispatcher do
    alias Questie.Request

    def dispatch(%Request{} = req) do
      hreq = %HTTPoison.Request{
        method: req.method,
        url: URI.to_string(req.url),
        body: req.body || "",
        headers: req.headers,
        params: req.params,
        options: req.dispatcher_opts
      }

      HTTPoison.request(hreq)
    end
  end

  defimpl Questie.Response.Adapter, for: HTTPoison.Response do
    def get_status(response) do
      response.status_code
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
