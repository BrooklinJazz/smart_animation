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
       speed_multiplier: 1,
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
      speed = round(1000 / ctx.assigns.speed_multiplier)
      Process.send_after(self(), :increment, speed)
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
    Process.send_after(self(), :increment, 1000)
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

  def handle_event("toggle_speed", _, ctx) do
    speed = ctx.assigns.speed_multiplier + 0.5
    next_multiplier = if speed > 4, do: 1, else: speed

    broadcast_event(ctx, "toggle_speed", %{"speed" => next_multiplier})

    {:noreply, assign(ctx, speed_multiplier: next_multiplier)}
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
          <span id="speed_multiplier">1x</span>
        </section>
      `;

      ctx.handleSync(() => {
        // Synchronously invokes change listeners
        document.activeElement &&
          document.activeElement.dispatchEvent(new Event("change"));
      });

      const start = ctx.root.querySelector("#start");
      const stop = ctx.root.querySelector("#stop");
      const reset = ctx.root.querySelector("#reset");
      const next = ctx.root.querySelector("#next");
      const previous = ctx.root.querySelector("#previous");
      const speed_multiplier = ctx.root.querySelector("#speed_multiplier");

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

      reset.addEventListener("click", (event) => {
        start.style.display = "inline"
        stop.style.display = "none"
        ctx.pushEvent("reset", {});
      });

      next.addEventListener("click", (event) => {
        ctx.pushEvent("next", {});
      });

      previous.addEventListener("click", (event) => {
        ctx.pushEvent("previous", {});
      });

      speed_multiplier.addEventListener("click", (event) => {
        ctx.pushEvent("toggle_speed", {});
      });

      ctx.handleEvent("toggle_speed", ({ speed }) => {
        speed_multiplier.innerHTML = `${speed}x`;
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
    }

    #speed_multiplier {
      position: absolute;
      right: 2rem;
      padding: 0 1rem;
    }

    .icon:hover, #reset:hover, #speed_multiplier:hover {
      color: black;
      cursor: pointer
    }
    """
  end
end
