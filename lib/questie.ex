defmodule Questie do
  alias __MODULE__.Request
  alias __MODULE__.Response

  def request(opts \\ []) do
    Request.new(opts)
  end

  # ---------------------------------------------------------------------------
  #  Request
  # ---------------------------------------------------------------------------

  defdelegate merge_opts(req, path), to: Request
  defdelegate merge_path(req, path), to: Request
  defdelegate dispatch(req), to: Request
  defdelegate basic_auth(req, username, password), to: Request
  defdelegate encode_with(req, encode), to: Request
  defdelegate encode_with(req, encode, opts), to: Request
  defdelegate put_body(req, body), to: Request
  defdelegate put_method(req, method), to: Request
  defdelegate put_url(req, url), to: Request
  defdelegate merge_path(req, path), to: Request

  # ---------------------------------------------------------------------------
  #  Response
  # ---------------------------------------------------------------------------

  defdelegate get_status(response), to: Response
  defdelegate expect_status(response, status_or_range), to: Response
end
