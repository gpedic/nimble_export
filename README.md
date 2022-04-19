# NimbleExport

NimbleExport is a simple streamed chunk export library based on [NimbleCSV](https://github.com/dashbitco/nimble_csv)

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `nimble_export` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:nimble_export, "~> 0.1.0"}
  ]
end
```

## Example Usage

```elixir

  # optionally define your NimbleCSV settings, the default is NimbleCSV.RFC4180
  NimbleCSV.define(MyCSV, separator: "\t", escape: "\"")

  def export_csv(conn, _params) do
    export_callback = NimbleExport.new(conn, dumper: MyCSV, batch_size: 200, filename: "lists")

    header = ["id", "title", "inserted_at", "updated_at"]

    stream =
      from(
        l in Lists,
        select: [l.id, l.title, l.inserted_at, l.updated_at],
        order_by: [asc: l.title]
      ) |> Repo.stream()

    result = Repo.transaction(fn ->
      Stream.concat([header], stream)
      |> export_callback.()
    end)

    with {:ok, conn} <- result do
      conn
    end
  end
```
