MODULE udp_communication
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
    VAR string play_msg;
    VAR string prec_msg;


    
    ! web params
    PERS num spd;
    PERS num int;
    PERS num lft;
    PERS num rgt;
    PERS num upr;
    PERS num lwr;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS bool play;
    PERS zonedata zone;
    PERS speeddata speed;
    PERS num y;
    PERS num z;
    
    
    
    PROC main()
        ! Reset params

        spd := 800;
        int := 100;
        lft := -600;
        rgt := 600;
        upr := 850;
        lwr := 250;
        acc := 100;
        jrk := 100;
        dac := 100;
        go := FALSE;
        play := TRUE;
        zone := [TRUE,0,0,0,0,0,0];
        speed := [800,1000,5000,1000];
        SetDO MyPauseSignal, 0;
        SetDO MyResetSignal, 0;

        ! delete old connections
        SocketClose udp_socket;

        ! Set connection parameters
        client_ip := "192.168.15.102";
        server_ip := "192.168.15.82";
        client_receiving_port := 66000;
        server_port := 1025;

        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, server_ip, server_port;


        !receive   
        WHILE TRUE DO
            receive_success := TRUE;
            SocketReceiveFrom udp_socket \Str := msg, client_ip, client_sending_port \Time := 10;
            
            !recieve_sucess gets set to false if socketReceiveFrom error handler is called
            if receive_success THEN
                cmd := StrPart(msg, 1, 3);
                str_length := StrLen(msg);
                ! Extracts (str_length - 4) total characters, starting at 5
                value := StrPart(msg, 5, (str_length - 4));
                parse_success := StrToVal(value, parsed_val);

                if parse_success THEN
                    response_msg := msg;
                    TEST cmd
                        CASE "spd":
                            spd := parsed_val;
                            speed := [spd, 1000, 5000, 1000];
                        CASE "zon":
                            TEST parsed_val
                                CASE 1000:
                                    zone := fine;
                                CASE 0:
                                    zone := z0;
                                CASE 20:
                                    zone := z20;
                                CASE 50:
                                    zone := z50;
                                CASE 100:
                                    zone := z100;
                                CASE 150:
                                    zone := z150;
                                CASE 200:
                                    zone := z200;
                            ENDTEST
                        CASE "int":
                            int := parsed_val;
                        CASE "lft":
                            lft := parsed_val;
                        CASE "rgt":
                            rgt := parsed_val;
                        CASE "upr":
                            upr := parsed_val;
                        CASE "lwr":
                            lwr := parsed_val;
                        CASE "acc":
                            acc := parsed_val;
                        CASE "jrk":
                            jrk := parsed_val;
                        CASE "dac":
                            dac := parsed_val;
                        CASE "go!":
                            go := TRUE;
                        CASE "pz!":
                            play := FALSE;
                            SetDO MyPauseSignal, 1;
                        CASE "pl!":
                            play := TRUE;
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                    ENDTEST
                ELSE
                    response_msg := "could not parse message";
                ENDIF
            ELSE
                response_msg := "no message recieved";
            ENDIF

            ! Prepare response message strings from settings
            if play THEN
                play_msg := "pl! 000";
            ELSE
                play_msg := "pz! 000";
            ENDIF

            TEST zone
                CASE fine:
                    prec_msg := "zon 1000";
                CASE z0:
                    prec_msg := "zon 0";
                CASE z20:
                    prec_msg := "zon 20";
                CASE z50:
                    prec_msg := "zon 50";
                CASE z100:
                    prec_msg := "zon 100";
                CASE z150:
                    prec_msg := "zon 150";
                CASE z200:
                    prec_msg := "zon 200";
            ENDTEST


            ! Send response in two chunks due to 80 char size limit
            json := "{";
            json := json + """spd"": " + NumToStr(spd, 0) + ",";
            json := json + """int"": " + NumToStr(int, 0) + ",";
            json := json + """lft"": " + NumToStr(lft, 0) + ",";
            json := json + """rgt"": " + NumToStr(rgt, 0);
            json := json + "}";
            SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

            json := "{";
            json := json + """upr"": " + NumToStr(upr, 0) + ",";
            json := json + """acc"": " + NumToStr(acc, 0) + ",";
            json := json + """jrk"": " + NumToStr(jrk, 0) + ",";
            json := json + """dac"": " + NumToStr(dac, 0) + ",";
            json := json + """lwr"": " + NumToStr(lwr, 0);
            json := json + "}";
            SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

            json := "{";
            json := json + """ply"": """ + play_msg + """,";
            json := json + """zon"": """ + prec_msg + """,";
            json := json + """msg"": """ + response_msg + """";
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



