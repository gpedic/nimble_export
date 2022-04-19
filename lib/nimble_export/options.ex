defmodule NimbleExport.Options do
  defstruct filename: "export",
    timestamp: true,
    dumper: NimbleCSV.RFC4180,
    batch_size: 100,
    end_marker: "--- EXPORT COMPLETE ---"
end
