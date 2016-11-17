defmodule Pan.FollowControllerTest do
  use Pan.ConnCase

  alias Pan.Follow
  @valid_attrs %{}
  @invalid_attrs %{}

  test "lists all entries on index", %{conn: conn} do
    conn = get conn, follow_path(conn, :index)
    assert html_response(conn, 200) =~ "Listing follows"
  end

  test "renders form for new resources", %{conn: conn} do
    conn = get conn, follow_path(conn, :new)
    assert html_response(conn, 200) =~ "New follow"
  end

  test "creates resource and redirects when data is valid", %{conn: conn} do
    conn = post conn, follow_path(conn, :create), follow: @valid_attrs
    assert redirected_to(conn) == follow_path(conn, :index)
    assert Repo.get_by(Follow, @valid_attrs)
  end

  test "does not create resource and renders errors when data is invalid", %{conn: conn} do
    conn = post conn, follow_path(conn, :create), follow: @invalid_attrs
    assert html_response(conn, 200) =~ "New follow"
  end

  test "shows chosen resource", %{conn: conn} do
    follow = Repo.insert! %Follow{}
    conn = get conn, follow_path(conn, :show, follow)
    assert html_response(conn, 200) =~ "Show follow"
  end

  test "renders page not found when id is nonexistent", %{conn: conn} do
    assert_error_sent 404, fn ->
      get conn, follow_path(conn, :show, -1)
    end
  end

  test "renders form for editing chosen resource", %{conn: conn} do
    follow = Repo.insert! %Follow{}
    conn = get conn, follow_path(conn, :edit, follow)
    assert html_response(conn, 200) =~ "Edit follow"
  end

  test "updates chosen resource and redirects when data is valid", %{conn: conn} do
    follow = Repo.insert! %Follow{}
    conn = put conn, follow_path(conn, :update, follow), follow: @valid_attrs
    assert redirected_to(conn) == follow_path(conn, :show, follow)
    assert Repo.get_by(Follow, @valid_attrs)
  end

  test "does not update chosen resource and renders errors when data is invalid", %{conn: conn} do
    follow = Repo.insert! %Follow{}
    conn = put conn, follow_path(conn, :update, follow), follow: @invalid_attrs
    assert html_response(conn, 200) =~ "Edit follow"
  end

  test "deletes chosen resource", %{conn: conn} do
    follow = Repo.insert! %Follow{}
    conn = delete conn, follow_path(conn, :delete, follow)
    assert redirected_to(conn) == follow_path(conn, :index)
    refute Repo.get(Follow, follow.id)
  end
end