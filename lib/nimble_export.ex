defmodule NimbleExport do
  @moduledoc """
  NimbleExport facilitates chunked exporting of CSV streams
  """
  alias NimbleExport.Options
  @doc """
  Create the export callback

  ## Options
  :timestamp - (boolean) wether to include a timestamp in the filename (default: true)
  :batch_size - (integer) the max number of rows to include in each chunk
  :dumper - (module) the module to use for dumping the CSV, must implement NimbleCSV behavior (default: NimbleCSV.RFC4180)
  :filename - (string) the filename (default: export)
  :end_marker - (string) the string to use to mark the end of export (default: "--- EXPORT COMPLETE ---")

  To include headers make them the first line in the stream

      stream = query |> Repo.stream()
      stream = Stream.concat([header], stream)

  ## Usage

    callback = create_export_callback(conn)
    stream = query |> Repo.stream()

    Repo.transaction(fn ->
      Stream.concat([header], stream)
      |> callback.()
    end)

  """
  @spec create_callback(conn :: Plug.Conn.t(), opts :: keyword()) :: function()
  def create_callback(%Plug.Conn{} = conn, opts \\ []) do
    options = struct(%Options{}, opts)

    filename = maybe_prepend_timestamp(options.timestamp, options.filename)

    setup_conn(conn, filename)
    |> do_create_callback(options)
  end

  defp do_create_callback(conn, export_opts) do
    callback = fn stream ->
      stream
      |> Stream.concat([[export_opts.end_marker]])
      |> Stream.chunk_every(export_opts.batch_size)
      |> Enum.reduce_while(conn, fn data, conn ->
        # credo:disable-for-next-line Credo.Check.Refactor.Nesting
        case Plug.Conn.chunk(conn, apply(export_opts.dumper, :dump_to_iodata, [data])) do
          {:ok, conn} ->
            {:cont, conn}

          {:error, :closed} ->
            {:halt, conn}
        end
      end)
    end

    callback
  end

  defp setup_conn(conn, filename) do
    conn
    |> Plug.Conn.put_resp_content_type("text/csv")
    |> Plug.Conn.put_resp_header(
      "content-disposition",
      "attachment; filename=#{filename}.csv"
    )
    |> Plug.Conn.send_chunked(:ok)
  end

  defp generate_timestamp_str() do
    DateTime.utc_now()
    |> DateTime.truncate(:second)
    |> DateTime.to_iso8601(:basic)
  end

  defp maybe_prepend_timestamp(true, filename), do: generate_timestamp_str() <> "_" <> filename
  defp maybe_prepend_timestamp(_, filename), do: filename
end
