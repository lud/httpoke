defmodule Questie do
  alias __MODULE__.Request
  alias __MODULE__.Response

  def request(opts \\ []) do
    Request.new(opts)
  end

  # ---------------------------------------------------------------------------
  #  Request
  # ---------------------------------------------------------------------------

  defdelegate authorization(req, raw), to: Request
  defdelegate basic_auth(req, username, password), to: Request
  defdelegate bearer_token(req, token), to: Request
  defdelegate dispatch(req), to: Request
  defdelegate encode_body(req, encode), to: Request
  defdelegate encode_body(req, encode, opts), to: Request
  defdelegate merge_headers(req, headers), to: Request
  defdelegate merge_opts(req, path), to: Request
  defdelegate merge_params(req, params), to: Request
  defdelegate merge_path(req, path), to: Request
  defdelegate put_body(req, body), to: Request
  defdelegate put_method(req, method), to: Request
  defdelegate put_url(req, url), to: Request

  # ---------------------------------------------------------------------------
  #  Response
  # ---------------------------------------------------------------------------

  defdelegate get_status(response), to: Response
  defdelegate expect_status(response, status_or_range), to: Response
  defdelegate get_header(response, name), to: Response
  defdelegate get_headers(response), to: Response
  defdelegate decode_body(response, decoder), to: Response
  defdelegate decode_body(response, decoder, opts), to: Response
  defdelegate get_body(response), to: Response
end
