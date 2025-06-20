MODULE speed_benchmark
    VAR socketdev udp_socket;
    VAR string client_ip;
    VAR num client_port;
    VAR byte msg_recv{1024};
    VAR byte msg_send{1024};
    VAR string str_data;
    VAR num recv_len;
    VAR num msgs_recieved;

    PROC main()
        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, "192.168.15.81", 1025;
        TPWrite "UDP server ready.";
        msgs_recieved := 0;

        WHILE TRUE DO
            SocketReceiveFrom udp_socket \Str := str_data, client_ip, client_port;
            msgs_recieved := msgs_recieved + 1;
            IF msgs_recieved MOD 1000 = 0 THEN
                TPWrite "Received from " + client_ip + ":" + NumToStr(client_port, 0);
                TPWrite "Got string: " + str_data;
                TPWrite NumToStr(msgs_recieved, 0);
            ENDIF

            ! Echo same message back
            ! msg_send{1} := msg_recv{1};
            ! SocketSendTo udp_socket, client_ip, client_port \Data := msg_send;
        ENDWHILE

    ENDPROC
ENDMODULE

