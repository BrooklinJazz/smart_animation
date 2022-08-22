defmodule SmartAnimation do
  use Kino.JS
  use Kino.JS.Live

  def new(function) do
    frame = Kino.Frame.new()
    Kino.render(function.(1))
    Kino.JS.Live.new(__MODULE__, {function, frame, nil})
  end

  def new(range, function) do
    frame = Kino.Frame.new()
    start.._finish = range
    Kino.render(function.(start))
    Kino.JS.Live.new(__MODULE__, {function, frame, range})
  end

  @impl true
  def init({function, frame, range}, ctx) do
    :timer.send_interval(1000, :increment)

    {start, finish} =
      case range do
        start..finish -> {start, finish}
        _ -> {1, nil}
      end

    {:ok,
     assign(ctx,
       finish: finish,
       start: start,
       step: start,
       running: false,
       frame: frame,
       function: function
     )}
  end

  def increment_step(ctx) do
    incremented_step =
      if ctx.assigns.finish && ctx.assigns.step >= ctx.assigns.finish,
        do: ctx.assigns.start,
        else: ctx.assigns.step + 1

    assign(ctx, step: incremented_step)
  end

  def decrement_step(ctx) do
    decremented_step =
      if ctx.assigns.step <= ctx.assigns.start,
        do: ctx.assigns.finish || ctx.assigns.start,
        else: ctx.assigns.step - 1

    assign(ctx, step: decremented_step)
  end

  @impl true
  def handle_info(:increment, ctx) do
    if ctx.assigns.running do
      {:noreply, ctx |> increment_step() |> update_animation()}
    else
      {:noreply, ctx}
    end
  end

  @impl true
  def handle_connect(ctx) do
    {:ok, %{}, ctx}
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
  def handle_event("restart", _, ctx) do
    {:noreply, assign(ctx, step: ctx.assigns.start, running: true) |> update_animation()}
  end

  @impl true
  def handle_event("next", _, ctx) do
    {:noreply, ctx |> increment_step() |> assign(running: false) |> update_animation()}
  end

  @impl true
  def handle_event("previous", _, ctx) do
    {:noreply, ctx |> decrement_step() |> assign(running: false) |> update_animation()}
  end

  def update_animation(ctx) do
    Kino.Frame.render(ctx.assigns.frame, ctx.assigns.function.(ctx.assigns.step))
    ctx
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("main.css");

      ctx.root.innerHTML = `
        <button id="start">START</button>
        <button id="stop">STOP</button>
        <button id="restart">RESTART</button>
        <button id="previous">PREVIOUS</button>
        <button id="next">NEXT</button>
      `;

      ctx.handleSync(() => {
        // Synchronously invokes change listeners
        document.activeElement &&
          document.activeElement.dispatchEvent(new Event("change"));
      });

      const start = ctx.root.querySelector("#start");
      start.addEventListener("click", (event) => {
        start.style.display = "none"
        stop.style.display = "inline"
        ctx.pushEvent("start", {});
      });

      const stop = ctx.root.querySelector("#stop");
      stop.style.display = "none"
      stop.addEventListener("click", (event) => {
        stop.style.display = "none"
        start.style.display = "inline"
        ctx.pushEvent("stop", {});
      });

      const restart = ctx.root.querySelector("#restart");
      restart.addEventListener("click", (event) => {
        ctx.pushEvent("restart", {});
      });

      const next = ctx.root.querySelector("#next");
      next.addEventListener("click", (event) => {
        ctx.pushEvent("next", {});
      });

      const previous = ctx.root.querySelector("#previous");
      previous.addEventListener("click", (event) => {
        ctx.pushEvent("previous", {});
      });
    }
    """
  end

  asset "main.css" do
    """
    """
  end
end
