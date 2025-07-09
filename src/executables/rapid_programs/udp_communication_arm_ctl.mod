MODULE udp_communication_arm_ctl
    VAR socketdev udp_socket;
    VAR string client_ip;
    VAR string server_ip;
    VAR num server_port;
    VAR num client_sending_port;
    VAR num client_receiving_port;
    VAR string msg;
    VAR string cmd;
    VAR string value;
    VAR num str_length;
    VAR num parsed_val;
    VAR bool parse_success;
    VAR bool receive_success;
    VAR string response_msg;
    VAR string json;

    ! web params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num mdr;
    PERS bool cb;
    PERS num y;
    PERS num z;
    
    
    
    PROC main()
        ! Reset params
        go := FALSE;
        cb := FALSE;
        SetDO MyResetSignal, 0;

        ! delete old connections
        SocketClose udp_socket;

        ! Set connection parameters
        client_ip := "192.168.15.76";
        server_ip := "192.168.15.81";
        client_receiving_port := 58000;
        server_port := 1026;

        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, server_ip, server_port;


        !receive   
        WHILE TRUE DO
            receive_success := TRUE;
            SocketReceiveFrom udp_socket \Str := msg, client_ip, client_sending_port \Time := 20;
            
            ! recieve_sucess gets set to false if socketReceiveFrom error handler is called
            if receive_success THEN
                cmd := StrPart(msg, 1, 3);
                str_length := StrLen(msg);
                ! Extracts (str_length - 4) total characters, starting at 5
                value := StrPart(msg, 5, (str_length - 4));
                parse_success := StrToVal(value, parsed_val);

                if parse_success THEN
                    response_msg := msg;
                    TEST cmd
                        CASE "mdr":
                            mdr := parsed_val;
                            go := TRUE;
                        CASE "cb!":
                            cb := TRUE;
                            go := TRUE;
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                    ENDTEST
                ELSE
                    response_msg := "could not parse message";
                ENDIF
            ELSE
                response_msg := "no message recieved";
            ENDIF
            
            WaitTime 0.03;
            json := "{";
            json := json + """msg"": """ + response_msg;
            json := json + "\\n\\npos: \\ny: " + NumToStr(y, 0);
            json := json + " z: " + NumToStr(z, 0) + """";
            json := json + "}";
            SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

        ENDWHILE        

        ERROR
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                receive_success := FALSE;
                TRYNEXT;
            ENDIF

        SocketClose udp_socket;
        
    ENDPROC


    
    
ENDMODULE



