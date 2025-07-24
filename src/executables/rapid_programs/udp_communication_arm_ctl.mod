MODULE udp_communication_arm_ctl
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
    VAR num spd;
    VAR num vel_y;
    VAR num vel_z;
    VAR num delta_y;
    VAR num delta_z;
    VAR num cur_error;

    ! PERS params
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num mdr;
    PERS num y_target;
    PERS num z_target;
    PERS num move_distance;
    
    PERS num prev_y_target;
    PERS num prev_z_target;

    VAR num speed_multiplier := 0.35; ! speed multiplier in mm, defaults to 250 mm/s each direction
    
    PROC main()
        ! Reset params
        go := FALSE;
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

        move_distance := 60;
        y_target := -600;
        z_target := 850;
        prev_y_target := y_target;
        prev_z_target := z_target;


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
                    response_msg := msg;
                    TEST cmd
                        CASE "mdr":
                            mdr := parsed_val;
                            go := TRUE;

                            TEST mdr
                                CASE -1:
                                    y_target := y_target + move_distance;
                                CASE -2:
                                    y_target := y_target - move_distance;
                                CASE -3:
                                    z_target := z_target + move_distance;
                                CASE -4:
                                    z_target := z_target - move_distance;
                                DEFAULT:
                                    IF mdr > 0 THEN
                                        move_distance := mdr;
                                    ENDIF
                            ENDTEST
                        CASE "con":
                            ! multiply joystick value by constant speed multiplier
                            delta_y := (speed_multiplier*parsed_val);
                            delta_z := (speed_multiplier*parsed_val2);

                            y_target := y_target - (delta_y);
                            z_target := z_target + (delta_z);

                            ! If target is far then use max speed

                            cur_error := Abs(y_target - prev_y_target) + Abs(z_target - prev_z_target);

                            IF (cur_error > 30) THEN
                                spd := 250*0.8*speed_multiplier;
                                speed := [spd, 1000, 5000, 1000];
                            ELSE
                                ! Multiply delta by publishing frequency to find speed in mm
                                vel_y := 250*delta_y;
                                vel_z := 250*delta_z;
                                spd := 0.4 * Sqrt(Pow(vel_y, 2) + Pow(vel_z, 2));
                                spd := Max(spd, 1);
                                speed := [spd, 1000, 5000, 1000];
                            ENDIF

                            if ((Abs(parsed_val) > 0.05) OR (Abs(parsed_val2) > 0.05)) THEN
                                go := TRUE;
                            ENDIF
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                    ENDTEST
                ELSE
                    response_msg := "could not parse message";
                ENDIF
            ELSE
                response_msg := "no message recieved";
            ENDIF
            
            WaitTime 0.00001;
            ! json := "{";
            ! json := json + """msg"": """ + response_msg;
            ! json := json + "\\n\\npos: \\ny: " + NumToStr(y_target, 0);
            ! json := json + " z: " + NumToStr(z_target, 0) + """";
            ! json := json + "}";
            ! SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

        ENDWHILE        

        ERROR
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                receive_success := FALSE;
                TRYNEXT;
            ENDIF

        SocketClose udp_socket;
        
    ENDPROC


    
    
ENDMODULE



