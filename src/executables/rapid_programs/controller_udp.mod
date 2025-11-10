MODULE controller_udp
    VAR socketdev udp_socket;
    VAR string client_ip;
    VAR string server_ip;
    VAR num server_port;
    VAR num client_sending_port;
    VAR num client_receiving_port;
    VAR string msg;
    VAR string msg2;
    VAR string cmd;
    VAR string value;
    VAR string value2;
    VAR num second_space;
    VAR num str_length;
    VAR num parsed_val;
    VAR num parsed_val2;
    VAR bool parse_success;
    VAR bool receive_success;
    VAR string response_msg;
    VAR string json;

    ! PERS params
    PERS bool go;
    PERS bool button_move;
    PERS num button_dir;
    PERS zonedata zone;
    PERS num mdr;
    PERS num con_y;
    PERS num con_z;
    PERS num input_spd;
    PERS num y_target;
    PERS num z_target;
    PERS num move_distance := 60;
    
    PROC main()
        ! Reset params
        go := FALSE;
        SetDO MyResetSignal, 0;

        ! delete old connections
        SocketClose udp_socket;

        ! Set connection parameters
        client_ip := "192.168.15.102";
        server_ip := "192.168.15.82";
        client_receiving_port := 4800;
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

                second_space := StrFind(msg, 5, STR_WHITE);

                if (second_space = (str_length + 1)) THEN
                    ! Extracts (str_length - 4) total characters, starting at 5
                    value := StrPart(msg, 5, (str_length - 4));
                    parse_success := StrToVal(value, parsed_val);
                ELSE
                    value := StrPart(msg, 5, (second_space - 4));
                    value2 := StrPart(msg, (second_space + 1), (str_length - second_space));
                    parse_success := (StrToVal(value, parsed_val) AND StrToVal(value2, parsed_val2));
                ENDIF


                if parse_success THEN
                    response_msg := "L: " + NumToStr(con_y, 2) + " R: " + NumToStr(con_z, 2) + "\\n";

                    TEST cmd
                        CASE "spd":
                            response_msg := response_msg + msg;
                            input_spd := parsed_val;
                        CASE "con":
                            con_y := parsed_val;
                            con_z := parsed_val2;
                        CASE "rs!":
                            response_msg := response_msg + msg;
                            SetDO MyResetSignal, 1;
                        CASE "mdr":
                            response_msg := response_msg + msg;
                            button_dir := parsed_val;
                            
                            IF button_dir > 0 THEN
                                move_distance := button_dir;
                            ELSE
                                button_move := TRUE;
                            ENDIF
                    ENDTEST
                ELSE
                    response_msg := "could not parse message";
                ENDIF
            ELSE
                response_msg := "no message recieved";
            ENDIF
            
            WaitTime 0.00001;
            json := "{";
            json := json + """spd"": " + NumToStr(input_spd, 0) + ",";
            json := json + """mdr"": " + NumToStr(move_distance, 0);
            json := json + "}";
            SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

            json := "{";
            json := json + """msg"": """ + response_msg;
            json := json + "\\n\\npos: \\ny: " + NumToStr(y_target, 0);
            json := json + " z: " + NumToStr(z_target, 0) + """";
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



