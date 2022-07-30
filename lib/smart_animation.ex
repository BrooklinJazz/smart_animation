defmodule SmartAnimation do
  use Kino.JS
  use Kino.JS.Live
  use Kino.SmartCell, name: "Plain code editor"

  @impl true
  def init(attrs, ctx) do
    source = attrs["source"] || ""
    {:ok, assign(ctx, source: source, frame: 0), reevaluate_on_change: true}
  end

  def handle_info(:increment, ctx) do
    {:noreply, assign(ctx, frame: ctx.assigns.frame + 1)}
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
    :timer.cancel(ctx.assigns.timer_ref)
    {:noreply, ctx}
  end

  # click start button
  # handle_event("start")
  # trigger increment interval
  # handle_info(:increment)
  # stop increment interval

  # handle_info(:start)
  # trigger :start increment

  @impl true
  def handle_event("start", _, ctx) do

    {:ok, timer_ref} = :timer.send_interval(1000, :increment)

    {:noreply, assign(ctx, timer_ref: timer_ref)}
  end

  # timer1 -> timer_ref: timer1
  # time2 -> timer_ref: timer2

  # disable start button after click
  # set a limit to the # of timers
  # check if timer exists: do nothing or start timer again?
  # set some running state: running: true or running: false, constant interval.


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
