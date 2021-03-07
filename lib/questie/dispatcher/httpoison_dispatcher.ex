defmodule Questie.HTTPoisonDispatcher do
  alias Questie.Request

  def dispatch(%Request{} = req) do
    hreq = %HTTPoison.Request{
      method: req.method,
      url: URI.to_string(req.url),
      body: req.body || "",
      headers: req.headers,
      params: %{},
      options: req.dispatcher_opts
    }

    HTTPoison.request(hreq)
  end
end

defimpl Questie.Response.Adapter, for: HTTPoison.Response do
  def get_status(response) do
    response.status_code
  end
end
