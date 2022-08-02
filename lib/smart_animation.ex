defmodule SmartAnimation do
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Plain code editor"

  @impl true
  def init(attrs, ctx) do
    source = attrs["source"] || ""
    :timer.send_interval(1000, :increment)
    {:ok, assign(ctx, source: source, frame: 0, running: false), reevaluate_on_change: true}
  end

  @impl true
  def handle_info(:increment, ctx) do
    frame = if ctx.assigns.running, do: ctx.assigns.frame + 1, else: ctx.assigns.frame

    {:noreply, assign(ctx, frame: frame)}
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{source: ctx.assigns.source}, ctx}
  end

  @impl true
  def handle_event("update", %{"source" => source}, ctx) do
    broadcast_event(ctx, "update", %{"source" => source})
    {:noreply, assign(ctx, source: source)}
  end

  @impl true
  def handle_event("stop", _, ctx) do
    {:noreply, assign(ctx, running: false)}
  end

  @impl true
  def handle_event("start", _, ctx) do
    {:noreply, assign(ctx, running: true)}
  end

  @impl true
  def to_attrs(ctx) do
    %{"source" => ctx.assigns.source, "frame" => ctx.assigns.frame}
  end

  @impl true
  def to_source(attrs) do
    """
    #{attrs["frame"]}
    """
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("main.css");

      ctx.root.innerHTML = `
        <textarea id="source"></textarea>
        <button id="stop">STOP</button>
        <button id="start">START</button>

      `;

      const textarea = ctx.root.querySelector("#source");
      textarea.value = payload.source;

      textarea.addEventListener("change", (event) => {
        ctx.pushEvent("update", { source: event.target.value });
      });

      ctx.handleEvent("update", ({ source }) => {
        textarea.value = source;
      });

      ctx.handleSync(() => {
        // Synchronously invokes change listeners
        document.activeElement &&
          document.activeElement.dispatchEvent(new Event("change"));
      });

      const stop = ctx.root.querySelector("#stop");
      stop.addEventListener("click", (event) => {
        ctx.pushEvent("stop", {});
      });

      const start = ctx.root.querySelector("#start");
      start.addEventListener("click", (event) => {
        ctx.pushEvent("start", {});
      });
    }
    """
  end

  asset "main.css" do
    """
    #source {
      box-sizing: border-box;
      width: 100%;
      min-height: 100px;
    }
    """
  end
end
