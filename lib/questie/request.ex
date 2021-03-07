defmodule Questie.Request.OptsCompiler do
  # We expect a keyword of option_name => fun_name, both atoms
  defmacro defoptsp(name, opt2fun) do
    Module.put_attribute(__CALLER__.module, name, Keyword.keys(opt2fun))

    _checkers =
      Enum.map(opt2fun, fn {opt, fun} ->
        quote bind_quoted: [name: name, opt: opt, fun: fun] do
          defp unquote(name)({unquote(opt), value}, req) do
            unquote(fun)(req, value)
          end
        end
      end)
  end
end

defmodule Questie.Request do
  alias __MODULE__
  require Questie.Request.OptsCompiler
  alias Questie.Request.OptsCompiler

  @enforce_keys [:__no_litteral__]
  defstruct headers: [],
            url: nil,
            method: nil,
            body: nil,
            assigns: %{},
            dispatcher: nil,
            dispatcher_opts: [],
            encoder: nil,
            skip_encoding_methods: ~w(get options head)a

  @methods ~w(get post put patch delete options head)a
  @loose_methods ~w(GET POST PUT PATCH DELETE OPTIONS HEAD)a ++
                   ~w(GET POST PUT PATCH DELETE OPTIONS HEAD)

  defguard is_method(method) when method in @methods
  defguard is_loose_method(method) when method in @loose_methods
  defguard is_url(url) when is_binary(url) or is_struct(url, URI)

  defguard is_dispatcher(dispatcher)
           when (is_atom(dispatcher) and nil != dispatcher) or
                  is_function(dispatcher, 1)

  def new(opts \\ []) do
    Enum.reduce(opts, Request.__struct__(), &check_init_opt/2)
  end

  def merge_opts(%Request{} = req, opts) do
    Enum.reduce(opts, req, &check_merge_opt/2)
  end

  ##
  ##
  ##

  defp check_init_opt({key, value}, %Request{} = req) when key in @req_opt do
    req_opt({key, value}, req)
  end

  defp check_init_opt(opt, req) do
    bad_option(opt, req)
  end

  defp check_merge_opt({key, value}, %Request{} = req) when key in @req_opt do
    # @todo define merge_opt if we need a different behaviour from init when
    #       overriding opts
    req_opt({key, value}, req)
  end

  defp check_merge_opt(opt, req) do
    bad_option(opt, req)
  end

  defp bad_option({key, value}, _) do
    raise ArgumentError,
      message: "unknown option #{inspect(key)} with value: #{inspect(value)}"
  end

  defp bad_option(other, _) do
    raise ArgumentError, message: "invalid option: #{inspect(other)}"
  end

  OptsCompiler.defoptsp(:req_opt,
    authorization: :authorization,
    basic_auth: :basic_auth,
    dispatcher: :put_dispatcher,
    headers: :merge_headers,
    method: :put_method,
    path: :merge_path,
    path: :merge_path,
    url: :put_url
  )

  defp req_opt({opt, v}, _) do
    raise ArgumentError,
      message: "invalid value for option #{opt}: #{inspect(v)}"
  end

  ##
  ##
  ##

  def put_url(%Request{} = req, url) when is_url(url) do
    %Request{req | url: URI.parse(url)}
  end

  def put_method(%Request{} = req, method) when is_method(method) do
    %Request{req | method: method}
  end

  def put_method(%Request{} = req, method) when is_loose_method(method) do
    # we should create a cast mapping function
    method = method |> to_string() |> String.downcase() |> String.to_existing_atom()
    %Request{req | method: method}
  end

  def put_method(%Request{} = req, other) do
    raise ArgumentError,
      message: "invalid method #{inspect(other)}, expected one of #{inspect(@methods)}"
  end

  def put_dispatcher(%Request{} = req, dispatcher)
      when is_dispatcher(dispatcher) do
    %Request{req | dispatcher: dispatcher}
  end

  def merge_path(%Request{url: nil}, path) when is_binary(path) do
    raise ArgumentError, message: "cannot merge path as base url is not set"
  end

  def merge_path(%Request{url: %URI{} = url} = req, path) when is_url(path) do
    %Request{req | url: URI.merge(url, path)}
  end

  @single_value_headers ~w(authorization)

  def merge_headers(%Request{headers: current_headers} = req, headers)
      when is_list(headers) do
    headers =
      headers
      |> Enum.map(&cast_header/1)
      |> Enum.reduce(current_headers, fn
        {:replace, k, v}, acc ->
          List.keystore(acc, k, 0, {k, v})

        {:merge, k, v}, acc ->
          case List.keyfind(acc, k, 0) do
            {^k, old} -> List.keystore(acc, k, 0, {k, "#{old}, #{v}"})
            nil -> [{k, v} | acc]
          end
      end)

    %Request{req | headers: headers}
  end

  defp cast_header({k, v}) do
    v = to_string(v)
    # if the header must be single-value we will replace it. Otherwise we will
    # merge the values
    case cast_header_key(k) do
      k when k in @single_value_headers -> {:replace, k, v}
      k -> {:merge, k, v}
    end
  end

  defp cast_header(header) do
    raise ArgumentError,
      message: "invalid header, expected a 2-tuple, got: #{inspect(header)}"
  end

  defp cast_header_key(k) do
    case k do
      k when is_binary(k) ->
        k

      k when is_atom(k) ->
        Atom.to_string(k)

      other ->
        raise ArgumentError, message: "invalid header name #{inspect(other)}"
    end
    |> String.downcase()
  end

  def basic_auth(req, {username, password}) do
    basic_auth(req, username, password)
  end

  def basic_auth(%Request{} = req, username, password)
      when is_binary(username) and is_binary(password) do
    authorization(req, "Basic " <> Base.encode64("#{username}:#{password}"))
  end

  def bearer_token(%Request{} = req, token) when is_binary(token) do
    authorization(req, "Bearer #{token}")
  end

  def authorization(%Request{} = req, auth) when is_binary(auth) do
    merge_headers(req, [{"authorization", auth}])
  end

  def encode_with(%Request{} = req, encode, opts) when is_function(encode, 2) do
    put_encoder(req, fn body -> encode.(body, opts) end)
  end

  def encode_with(%Request{} = req, encoder) when is_function(encoder, 1) do
    put_encoder(req, encoder)
  end

  def put_encoder(req, encoder) do
    %Request{req | encoder: encoder}
  end

  def put_body(%Request{} = req, body) do
    %Request{req | body: body}
  end

  ##
  ##
  ##

  def dispatch(%Request{dispatcher: dispatcher} = req) do
    dispatch(req, dispatcher)
  end

  def dispatch(%Request{} = req, dispatcher) do
    with {:ok, req} <- validate(req),
         {:ok, req} <- prepare(req) do
      do_dispatch(req, req.dispatcher)
    else
      {:error, _} = err -> err
    end
  end

  @doc false
  def do_dispatch(%Request{} = req, dispatcher) when is_atom(dispatcher) do
    dispatcher.dispatch(req)
  end

  def do_dispatch(%Request{} = req, dispatcher) when is_function(dispatcher, 1) do
    dispatcher.(req)
  end

  defp prepare(%Request{} = req) do
    with {:ok, req} <- prepare_body(req) do
      {:ok, req}
    else
      {:error, _} = err -> err
    end
  end

  defp prepare_body(%Request{encoder: nil} = req) do
    {:ok, req}
  end

  defp prepare_body(%Request{encoder: encoder} = req) when is_function(encoder, 1) do
    %Request{method: method, encoder: encoder, body: body, skip_encoding_methods: skipped} = req
    # If the user wants to send a body with a GET request it is legit. For
    # convenience, we have a :skip_encoding_methods list that will make the
    # behaviour more natural.
    if nil == body and is_list(skipped) and method in skipped do
      {:ok, req}
    else
      case encoder.(req.body) do
        {:ok, body} -> {:ok, %Request{req | body: body}}
        {:error, _} = err -> err
      end
    end
  end

  @validators [:url, :method, :dispatcher]

  def validate(req) do
    Enum.reduce(@validators, {:ok, req}, &validate_loop/2)
  end

  defp validate_loop(validator, {:ok, req}) do
    validate(validator, req)
  end

  defp validate_loop(_validator, {:error, _} = err) do
    err
  end

  defp validate(:url, %Request{url: url} = req) do
    case url do
      %URI{} -> {:ok, req}
      nil -> {:error, "the url is not set"}
      invalid -> {:error, "invalid url #{inspect(invalid)}"}
    end
  end

  defp validate(:method, %Request{method: method} = req) do
    case method do
      m when m in @methods -> {:ok, req}
      nil -> {:error, "the method is not set"}
      invalid -> {:error, "invalid method #{inspect(invalid)}"}
    end
  end

  defp validate(:dispatcher, %Request{dispatcher: dispatcher} = req) do
    case dispatcher do
      d when is_dispatcher(d) -> {:ok, req}
      nil -> {:error, "the dispatcher is not set"}
      invalid -> {:error, "invalid dispatcher #{inspect(invalid)}"}
    end
  end

  defp validate(other, %Request{} = _req) do
    raise ArgumentError, message: "unknown request validator #{inspect(other)}"
  end
end
