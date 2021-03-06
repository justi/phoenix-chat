// NOTE: The contents of this file will only be executed if
// you uncomment its entry in "web/static/js/app.js".

// To use Phoenix channels, the first step is to import Socket
// and connect at the socket path in "lib/my_app/endpoint.ex":
import {Socket} from "phoenix"

let socket = new Socket("/socket", {params: {token: window.userToken}})

// When you connect, you'll often need to authenticate the client.
// For example, imagine you have an authentication plug, `MyAuth`,
// which authenticates the session and assigns a `:current_user`.
// If the current user exists you can assign the user's token in
// the connection for use in the layout.
//
// In your "web/router.ex":
//
//     pipeline :browser do
//       ...
//       plug MyAuth
//       plug :put_user_token
//     end
//
//     defp put_user_token(conn, _) do
//       if current_user = conn.assigns[:current_user] do
//         token = Phoenix.Token.sign(conn, "user socket", current_user.id)
//         assign(conn, :user_token, token)
//       else
//         conn
//       end
//     end
//
// Now you need to pass this token to JavaScript. You can do so
// inside a script tag in "web/templates/layout/app.html.eex":
//
//     <script>window.userToken = "<%= assigns[:user_token] %>";</script>
//
// You will need to verify the user token in the "connect/2" function
// in "web/channels/user_socket.ex":
//
//     def connect(%{"token" => token}, socket) do
//       # max_age: 1209600 is equivalent to two weeks in seconds
//       case Phoenix.Token.verify(socket, "user socket", token, max_age: 1209600) do
//         {:ok, user_id} ->
//           {:ok, assign(socket, :user, user_id)}
//         {:error, reason} ->
//           :error
//       end
//     end
//
// Finally, pass the token to the Socket constructor as above.
// Or, remove it from the constructor if you don't care about
// authentication.

socket.connect()
let channel   = socket.channel("random:lobby", {});
let list      = $('#message-list');
let message   = $('#message');
let name      = $('#name');
let disappear = $('#disappear');

message.on('keypress', event => {
    key_press_handle(event);
});

disappear.on('keypress', event => {
    key_press_handle(event);
});

function key_press_handle(event) {
    if (event.keyCode == 13) {
        channel.push('shout', { name: name.val(), message: message.val(), disappear: disappear.is(':checked')});
        message.val('');
    }
};

function get_line_message(payload) {
    if (payload.disappear) {
        return `<div id="ts_${payload.id}"><b>${payload.name || 'Anonymous'}:</b> <font color="red">${payload.message}</font><br></div>`;
    } else {
        return `<b>${payload.name || 'Anonymous'}:</b> ${payload.message}<br>`;
    }
}

channel.on('shout', payload => {
    list.append(get_line_message(payload));
    list.prop({scrollTop: list.prop("scrollHeight")});
});

channel.join()
    .receive("ok", resp => { console.log("Joined successfully", resp) })
    .receive("error", resp => { console.log("Unable to join", resp) })

channel.on('messages_history', messages => {

    list.empty();
    let messages_list = messages["messages"];

    messages_list.forEach( function(msg) {
        list.append(get_line_message(msg));
        list.prop({scrollTop: list.prop("scrollHeight")});
    });
});

channel.on('message_delete', response => {
    list.find("#ts_"+response["id"]).remove();
});

export default socket