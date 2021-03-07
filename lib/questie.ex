defmodule Questie do
  alias __MODULE__.Request

  def request(opts \\ []) do
    Request.new(opts)
  end

  defdelegate merge_path(req, path), to: Request
  defdelegate dispatch(req), to: Request
  defdelegate basic_auth(req, username, password), to: Request
  defdelegate encode_with(req, encode), to: Request
  defdelegate encode_with(req, encode, opts), to: Request
  defdelegate put_body(req, body), to: Request
end
