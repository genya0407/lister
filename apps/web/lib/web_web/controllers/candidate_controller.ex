defmodule WebWeb.CandidateController do
  use WebWeb, :controller

  def index(conn, %{"owner_screen_name" => owner_screen_name, "slug" => slug, "hints" => hints}) do
    list_member_ids =
      Twitter.Read.list_members(%{
        owner_screen_name: owner_screen_name,
        slug: slug
      })
      |> Enum.map(& &1.id)

    candidates =
      hints
      |> String.split(",")
      |> Twitter.friends_intersection()
      |> MapSet.difference(list_member_ids |> MapSet.new())
      |> Enum.to_list()
      |> Twitter.attach_profile()
      |> Enum.map(fn u ->
        %{id: Integer.to_string(u.id), screen_name: u.screen_name, name: u.name}
      end)

    json(conn, %{"candidates" => candidates})
  end

  def create(conn, %{
        "owner_screen_name" => owner_screen_name,
        "slug" => slug,
        "user_ids" => user_ids
      }) do
    user_ids = user_ids |> Enum.map(&String.to_integer/1)
    Twitter.Write.add_to_list(owner_screen_name, slug, user_ids)

    json(conn, %{"msg" => "success"})
  end
end
