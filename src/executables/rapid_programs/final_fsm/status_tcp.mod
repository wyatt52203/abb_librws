MODULE status_tcp
    VAR socketdev server_socket;
    VAR socketdev client_socket;
    VAR string server_ip;
    VAR num server_port;
    VAR string msg;
    VAR string cmd;
    VAR bool parse_success;
    VAR bool receive_success;
    VAR bool accept_success;
    VAR string json;
    VAR string prec_msg;
    VAR string state_msg;
    VAR bool send;
    VAR bool listening;
    VAR bool receiving;


    
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

    PROC main()
        ! Reset params
        send := FALSE;

        ! delete old connections
        SocketClose server_socket;
        SocketClose client_socket;

        ! Set connection parameters
        server_ip := "192.168.15.82";
        server_port := 2001;

        SocketCreate server_socket;
        SocketBind server_socket, server_ip, server_port;
        SocketListen server_socket;

        listening := TRUE;
        receiving := FALSE;

        !receive   
        WHILE TRUE DO

            IF listening THEN
                accept_success := TRUE;
                SocketAccept server_socket, client_socket;
                IF accept_success THEN
                    listening := FALSE;
                    receiving := TRUE;
                ENDIF
            ENDIF

            IF receiving THEN
                receive_success := TRUE;
                SocketReceive client_socket \Str := msg;
                
                !recieve_sucess gets set to false if socketReceive error handler is called
                if receive_success THEN
                    cmd := StrPart(msg, 1, 3);

                    if cmd = "snd" THEN
                        send := TRUE;
                    ENDIF
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
                    json := json + ",\\n";
                    SocketSend client_socket \Str := json;

                    json := """xrd"": " + NumToStr(x_read, 0) + ",";
                    json := json + """yrd"": " + NumToStr(y_read, 0) + ",";
                    json := json + """zrd"": " + NumToStr(z_read, 0) + ",";
                    json := json + """state"": """ + state_msg + """";
                    json := json + ",\\n";
                    SocketSend client_socket \Str := json;

                    json := """xtg"": " + NumToStr(x_target, 0) + ",";
                    json := json + """ytg"": " + NumToStr(y_target, 0) + ",";
                    json := json + """ztg"": " + NumToStr(z_target, 0);
                    json := json + "}\\n";
                    SocketSend client_socket \Str := json;

                    send := FALSE;
                ENDIF
            ENDIF

        ENDWHILE        
   

        ERROR
            IF ERRNO = ERR_SOCK_TIMEOUT THEN
                IF listening THEN
                    accept_success := FALSE;
                    TRYNEXT;
                ELSEIF receiving THEN
                    receive_success := FALSE;
                    TRYNEXT;
                ENDIF
            ENDIF

            IF ERRNO = ERR_SOCK_CLOSED THEN
                ExitCycle;
            ENDIF


        SocketClose server_socket;
        SocketClose client_socket;
        
    ENDPROC    
    
ENDMODULE
