MODULE slider_arm_ctl
    VAR socketdev udp_socket;
    VAR string client_ip;
    VAR num client_port;
    VAR string msg;
    VAR num y := 0;  ! Initial value within bounds
    VAR num z := 200;  ! Initial value within bounds
    VAR bool y_z := TRUE;  ! Default move y, if false move z
    VAR num parsed_val;
    VAR robtarget target;
    VAR bool success;
    VAR speeddata speed;
    
    PROC main()
        SocketCreate udp_socket \UDP;
        SocketBind udp_socket, "192.168.15.81", 1025;
        TPWrite "UDP server ready.";


        !receive   
        WHILE TRUE DO
            SocketReceiveFrom udp_socket \Str := msg, client_ip, client_port;
            
            ! Print message no matter what
            ! TPWrite "Received: " + msg;

            success := StrToVal(msg, parsed_val);

            IF parsed_val = -1 THEN
                y_z := TRUE;
            ELSEIF parsed_val = -2 THEN
                y_z := FALSE;
            ELSE
                IF y_z THEN
                    y := parsed_val;
                ELSE
                    z := parsed_val;
                ENDIF
            ENDIF

            ! Perform movement
            speed := v200;
            MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, z200, tool0;
            
        ENDWHILE        

        ERROR
            TPWrite "ERRNO: " + ValToStr(ERRNO);
            TPWrite "error encountered, continuing to next step";
            ! TRYNEXT;

        TPWrite "closing now";
        SocketClose udp_socket;
        
    ENDPROC


    
    
ENDMODULE



