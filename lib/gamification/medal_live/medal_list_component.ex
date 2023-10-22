# credo:disable-for-this-file Credo.Check.Readability.Specs
defmodule UneebeeWeb.Components.MedalList do
  @moduledoc false
  use UneebeeWeb, :html

  alias Uneebee.Gamification.MedalUtils

  attr :kind, :atom, values: [:gold, :silver, :bronze], required: true
  attr :medals, :list, required: true

  def medal_list(assigns) do
    ~H"""
    <section class="mb-8">
      <h2 class={[
        "mb-2 font-bold",
        @kind == :gold && "text-warning-dark2x",
        @kind == :silver && "text-gray-dark2x",
        @kind == :bronze && "text-bronze-dark2x"
      ]}>
        <%= list_title(@kind, total_medals(@medals)) %>
      </h2>

      <dl class="grid grid-cols-2 gap-4 sm:grid-cols-3">
        <.medal_card :for={medal <- @medals} medal={MedalUtils.medal(medal.reason)} kind={@kind} count={medal.count} />
      </dl>
    </section>
    """
  end

  defp medal_card(assigns) do
    ~H"""
    <div
      id={"medal-#{@medal.key}"}
      class={[
        "flex flex-col items-center justify-center gap-1 rounded-2xl p-4 text-center",
        @kind == :gold && "bg-warning-light3x text-warning-dark2x",
        @kind == :silver && "bg-gray-light3x text-gray-dark2x",
        @kind == :bronze && "bg-bronze-light3x text-bronze-dark2x"
      ]}
    >
      <.icon name="tabler-medal" />

      <dt class="text-sm font-black"><%= @medal.label %></dt>
      <dd class="flex-1 text-sm"><%= @medal.description %></dd>

      <dd class={[
        "mt-4 flex h-12 w-12 flex-col items-center justify-center rounded-full font-black",
        @kind == :gold && "bg-warning-dark2x text-warning-light3x",
        @kind == :silver && "bg-gray-dark2x text-gray-light3x",
        @kind == :bronze && "bg-bronze-dark2x text-bronze-light3x"
      ]}>
        <%= @count %>
      </dd>
    </div>
    """
  end

  defp list_title(:gold, count), do: dngettext("gamification", "%{count} gold medal", "%{count} gold medals", count, count: count)
  defp list_title(:silver, count), do: dngettext("gamification", "%{count} silver medal", "%{count} silver medals", count, count: count)
  defp list_title(:bronze, count), do: dngettext("gamification", "%{count} bronze medal", "%{count} bronze medals", count, count: count)

  defp total_medals(medals), do: Enum.reduce(medals, 0, fn medal, acc -> acc + medal.count end)
end