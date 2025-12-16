MODULE yz_arm_ctl
    VAR socketdev mySocket;
    VAR socketdev clientSocket;
    VAR socketstatus stat;
    VAR string ipAddress := "192.168.15.81";  ! Controller IP
    VAR num port := 1025;
    VAR string msg;
    VAR num y := 0;  ! Initial value within bounds
    VAR num z := 100;  ! Initial value within bounds
    VAR num move_distance := 50;  ! Default move distance
    VAR num parsed_val;
    VAR robtarget target;
    VAR bool success;
    VAR speeddata speed;
    
    PROC main()
        !delete old connections
        SocketClose clientSocket;
        SocketClose mySocket;
        
        !connect
        SocketCreate mySocket;
        SocketBind mySocket, ipAddress, port;
    
        SocketListen mySocket;
    
        TPWrite "Waiting for connection...";
        SocketAccept mySocket, clientSocket;
        TPWrite "Client connected!";
        
        !receive   
        WHILE TRUE DO
            SocketReceive clientSocket \Str:= msg;
            
            ! Print message no matter what
            TPWrite "Received: " + msg;

            success := StrToVal(msg, parsed_val);

            if success THEN
                TEST parsed_val
                    CASE -1:
                        y := y + move_distance;
                    CASE -2:
                        y := y - move_distance;
                    CASE -3:
                        z := z + move_distance;
                    CASE -4:
                        z := z - move_distance;
                    DEFAULT:
                        IF parsed_val > 0 THEN
                            move_distance := parsed_val;
                        ENDIF
                ENDTEST
            ENDIF

            ! Enforce Y bounds [-600, 600]
            IF y > 600 THEN
                y := 600;
            ELSEIF y < -600 THEN
                y := -600;
            ENDIF

            ! Enforce Z bounds [100, 700]
            IF z > 700 THEN
                z := 700;
            ELSEIF z < 100 THEN
                z := 100;
            ENDIF

            ! Perform movement
            speed := v300;
            MoveL [[300, y, z], [0,1,0,0], [-1,-1,0,1], [9E9,9E9,9E9,9E9,9E9,9E9]], speed, z100, tool0;
            
        ENDWHILE        


        TPWrite "closing now";
        SocketClose clientSocket;
        SocketClose mySocket;
        
    ENDPROC


    
    
ENDMODULE



