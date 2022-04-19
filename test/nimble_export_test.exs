defmodule NimbleExportTest do
  use ExUnit.Case
  use Plug.Test
  require ExUnitProperties
  NimbleCSV.define(TestCSV, separator: "\t", escape: "\"")

  setup do
    csv_stream = StreamData.list_of(StreamData.string(:alphanumeric), length: 8)

    [csv_stream: csv_stream, conn: conn(:get, "/test")]
  end

  test "exports a stream to csv file", %{conn: conn, csv_stream: csv_stream} do
    callback = NimbleExport.create_callback(conn)

    assert is_function(callback)
    resp = callback.(Stream.take(csv_stream, 10))
    assert %Plug.Conn{} = resp
    assert resp.status == 200
    assert resp.state == :chunked
    assert ["text/csv; charset=utf-8"] = get_resp_header(resp, "content-type")
    assert ["attachment; filename=" <> filename] = get_resp_header(resp, "content-disposition")
    assert NimbleCSV.RFC4180.parse_string(resp.resp_body) |> length()
    assert String.match?(filename, ~r/^[0-9]+T[0-9]+Z_export.csv$/)
  end

  test "filename option sets the filename", %{conn: conn, csv_stream: csv_stream} do
    callback = NimbleExport.create_callback(conn, filename: "testname")

    assert ["attachment; filename=" <> filename] =
             get_resp_header(callback.(Stream.take(csv_stream, 1)), "content-disposition")

    assert String.match?(filename, ~r/^[0-9]+T[0-9]+Z_testname.csv$/)
  end

  test "set timestamp option to false disables timestamp", %{conn: conn, csv_stream: csv_stream} do
    callback = NimbleExport.create_callback(conn, filename: "testname", timestamp: false)

    assert ["attachment; filename=" <> filename] =
             get_resp_header(callback.(Stream.take(csv_stream, 1)), "content-disposition")

    assert String.match?(filename, ~r/^testname.csv$/)
  end

  test "end_marker option sets the last line", %{conn: conn, csv_stream: csv_stream} do
    callback = NimbleExport.create_callback(conn)
    resp = callback.(Stream.take(csv_stream, 1))
    assert resp.resp_body =~ "\r\n--- EXPORT COMPLETE ---\r\n"

    callback_custom = NimbleExport.create_callback(conn, end_marker: "---TEST---")
    resp_custom = callback_custom.(Stream.take(csv_stream, 1))
    assert resp_custom.resp_body =~ "\r\n---TEST---\r\n"
  end

  test "dumper option sets the nimble csv dumper to use", %{conn: conn, csv_stream: csv_stream} do
    take_count = 10

    resp =
      Stream.take(csv_stream, take_count)
      |> NimbleExport.create_callback(conn, dumper: TestCSV).()

    # length has to include the end_marker
    assert TestCSV.parse_string(resp.resp_body, skip_headers: false) |> length() == take_count + 1
  end
end
