defmodule SmartAnimation do
  use Kino.JS
  use Kino.JS.Live

  def new(function) do
    frame = Kino.Frame.new()
    Kino.render(frame)
    Kino.Frame.render(frame, function.(1))
    Kino.JS.Live.new(__MODULE__, {function, frame, nil})
  end

  def new(range, function) do
    frame = Kino.Frame.new()
    Kino.render(frame)
    start.._finish = range
    Kino.Frame.render(frame, function.(start))
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

  def update_animation(ctx) do
    Kino.Frame.render(ctx.assigns.frame, ctx.assigns.function.(ctx.assigns.step))
    ctx
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
  def handle_event("reset", _, ctx) do
    {:noreply, assign(ctx, step: ctx.assigns.start, running: false) |> update_animation()}
  end

  @impl true
  def handle_event("next", _, ctx) do
    {:noreply, ctx |> increment_step() |> assign(running: false) |> update_animation()}
  end

  @impl true
  def handle_event("previous", _, ctx) do
    {:noreply, ctx |> decrement_step() |> assign(running: false) |> update_animation()}
  end

  asset "main.js" do
    """
    export function init(ctx, payload) {
      ctx.importCSS("main.css");
      ctx.importCSS("https://cdn.jsdelivr.net/npm/remixicon@2.5.0/fonts/remixicon.css")

      ctx.root.innerHTML = `
        <section class="control">
          <span id="reset">Reset</span>
          <i id="previous" class="ri-arrow-left-fill icon"></i>
          <i id="start" class="ri-play-fill icon"></i>
          <i id="stop" class="ri-stop-fill icon"></i>
          <i id="next" class="ri-arrow-right-fill icon"></i>
        </section>
      `;

      ctx.handleSync(() => {
        // Synchronously invokes change listeners
        document.activeElement &&
          document.activeElement.dispatchEvent(new Event("change"));
      });

      const start = ctx.root.querySelector("#start");
      const stop = ctx.root.querySelector("#stop");

      stop.style.display = "none"

      start.addEventListener("click", (event) => {
        start.style.display = "none"
        stop.style.display = "inline"
        ctx.pushEvent("start", {});
      });

      stop.addEventListener("click", (event) => {
        stop.style.display = "none"
        start.style.display = "inline"
        ctx.pushEvent("stop", {});
      });

      const reset = ctx.root.querySelector("#reset");
      reset.addEventListener("click", (event) => {
        ctx.pushEvent("reset", {});
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
    .control {
      padding: 1rem;
      background-color: rgb(240 245 249);
      border-radius: 0.5rem;
      font-weight: 500;
      color: rgb(97 117 138);
      font-family: Inter, system-ui,-apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif, Apple Color Emoji, Segoe UI Emoji;
      display: flex;
      justify-content: center;
      align-items: center;
    }

    .icon {
        font-size: 1.875rem;
        padding: 0 1rem;
    }

    #reset {
      position: absolute;
      left: 1rem;
      top: auto;
      bottom: auto;
    }

    .icon:hover, #reset:hover {
      color: black;
      cursor: pointer
    }
    """
  end
end
