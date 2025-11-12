MODULE status_socket
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
    VAR string prec_msg;
    VAR string state_msg;
    VAR bool send;


    
    ! Shared Params
    PERS num spd;
    PERS num acc;
    PERS num jrk;
    PERS num dac;
    PERS bool go;
    PERS zonedata zone;
    PERS speeddata speed;


    PERS num x_read;
    PERS num y_read;
    PERS num z_read;
    PERS num x_target;
    PERS num y_target;
    PERS num z_target;

    PERS num state;
    ! STATE DEFINITION
    ! 0 = IDLE
    ! 1 = RUNNING
    ! 2 = PAUSED
    ! 3 = ABORTED


    PROC EnforceBounds(INOUT num x, INOUT num y, INOUT num z)
        ! Enforce Y bounds [-450, 450]

        ! +750 height in safety, 700 here
        ! -250 height - soft, -350 safety config

        ! left side -500 safety config 
        ! software -450

        ! right side safety 550
        ! software 450

        IF y > 450 THEN
            y := 450;
        ELSEIF y < -450 THEN
            y := -450;
        ENDIF

        ! Enforce Z bounds [10, 850]
        IF z > 700 THEN
            z := 700;
        ELSEIF z < -250 THEN
            z := -250;
        ENDIF

        IF x > 450 THEN
            x := 450;
        ELSEIF x < 250 THEN
            x := 250;
        ENDIF
    ENDPROC
    
    PROC main()
        ! Reset params
        go := FALSE;
        send := FALSE;
        SetDO MyResetSignal, 0;
        SetDO MyEmergencyStopSignal, 0;
        SetDO MyPauseSignal, 0;
        SetDO MyContinueSignal, 0;

        ! delete old connections
        SocketClose udp_socket;

        ! Set connection parameters
        client_ip := "192.168.15.102";
        server_ip := "192.168.15.82";
        client_receiving_port := 5001;
        server_port := 1027;

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
                        CASE "acc":
                            acc := parsed_val;
                        CASE "jrk":
                            jrk := parsed_val;
                        CASE "dac":
                            dac := parsed_val;
                        CASE "go!":
                            go := TRUE;
                        CASE "xtg":
                            x_target := parsed_val;
                        CASE "ytg":
                            y_target := parsed_val;
                        CASE "ztg":
                            z_target := parsed_val;
                        CASE "pz!":
                            SetDO MyPauseSignal, 1;
                        CASE "pl!":
                            SetDO MyContinueSignal, 1;
                        CASE "rs!":
                            SetDO MyResetSignal, 1;
                        CASE "emr":
                            SetDO MyEmergencyStopSignal, 1;
                        CASE "snd":
                            send := TRUE;
                    ENDTEST

                    EnforceBounds x_target, y_target, z_target;
                ELSE
                    response_msg := "could not parse message";
                ENDIF
            ELSE
                response_msg := "no message recieved";
            ENDIF

            IF send THEN
                ! Prepare response message strings from settings
                ! STATE DEFINITION
                ! 0 = IDLE
                ! 1 = RUNNING
                ! 2 = PAUSED
                ! 3 = ABORTED
                TEST state
                    CASE 0:
                        state_msg := "IDLE";
                    CASE 1:
                        state_msg := "RUNNING";
                    CASE 2:
                        state_msg := "PAUSED";
                    CASE 3:
                        state_msg := "ABORTED";
                ENDTEST

                TEST zone
                    CASE fine:
                        prec_msg := """zon"": 1000";
                    CASE z0:
                        prec_msg := """zon"": 0";
                    CASE z20:
                        prec_msg := """zon"": 20";
                    CASE z50:
                        prec_msg := """zon"": 50";
                    CASE z100:
                        prec_msg := """zon"": 100";
                    CASE z150:
                        prec_msg := """zon"": 150";
                    CASE z200:
                        prec_msg := """zon"": 200";
                ENDTEST
                
                ! Send response in two chunks due to 80 char size limit
                json := "{";
                json := json + """spd"": " + NumToStr(spd, 0) + ",";
                json := json + """acc"": " + NumToStr(acc, 0) + ",";
                json := json + """jrk"": " + NumToStr(jrk, 0) + ",";
                json := json + """dac"": " + NumToStr(dac, 0) + ",";
                json := json + prec_msg;
                json := json + "}";
                SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

                json := "{";
                json := json + """xrd"": " + NumToStr(x_read, 0) + ",";
                json := json + """yrd"": " + NumToStr(y_read, 0) + ",";
                json := json + """zrd"": " + NumToStr(z_read, 0) + ",";
                json := json + """state"": """ + state_msg + """";
                json := json + "}";
                SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

                json := "{";
                json := json + """xtg"": " + NumToStr(x_target, 0) + ",";
                json := json + """ytg"": " + NumToStr(y_target, 0) + ",";
                json := json + """ztg"": " + NumToStr(z_target, 0) + ",";
                json := json + """msg"": """ + response_msg + """";
                json := json + "}";
                SocketSendTo udp_socket, client_ip, client_receiving_port \Str := json;

                send := FALSE;
            ENDIF

        ENDWHILE        
   

        ERROR
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                receive_success := FALSE;
                TRYNEXT;
            ENDIF

        SocketClose udp_socket;
        
    ENDPROC    
    
ENDMODULE
