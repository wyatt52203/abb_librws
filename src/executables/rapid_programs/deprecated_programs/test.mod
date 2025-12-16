MODULE simple_arm_ctl
    
    VAR robtarget Forward:=[[-0.577069103717804, -27.6019439697266, 983.39697265625], [0.459520936012268, 0.440142691135406, 0.534661531448364, -0.556104302406311], [-2, 0, -1, 4], [9000000000, 9000000000, 9000000000, 9000000000, 9000000000, 9000000000]];
    VAR robtarget Leftdown:=[[594.463439941406, -342.565734863281, 478.881408691406], [0.00284174038097262, -0.156440258026123, -0.987652719020844, -0.0077797407284379], [-1, 0, -1, 0], [9000000000, 9000000000, 9000000000, 9000000000, 9000000000, 9000000000]];
    VAR robtarget Forwarddown:=[[13.1291675567627, -824.460510253906, 418.283538818359], [0.0437294542789459, 0.624885141849518, 0.778625667095184, -0.036719735711813], [-1, 0, -1, 0], [9000000000, 9000000000, 9000000000, 9000000000, 9000000000, 9000000000]];
    VAR robtarget Rightdown:=[[-695.970581054688, -3.26948618888855, 393.924163818359], [0.0214464329183102, 0.994738101959229, 0.087247163057327, -0.0492351017892361], [-2, 0, -1, 0], [9000000000, 9000000000, 9000000000, 9000000000, 9000000000, 9000000000]];
    
    VAR socketdev mySocket;
    VAR socketdev clientSocket;
    VAR socketstatus stat;
    VAR string ipAddress := "192.168.15.81";  ! Controller IP
    VAR num port := 1025;
    VAR byte msg{1024};
    VAR string typed_msg;
    VAR num num_msg;
    VAR num motor_angle;
    
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
            SocketReceive clientSocket \Data:= msg;
            num_msg := msg{1} - 48;
            
            ! Print message no matter what
            TPWrite "Received: ";
            typed_msg := NumToStr(msg{1}, 3);
            TPWrite typed_msg;
            
            IF num_msg = 1 THEN
                MoveJ Forward, v1500, fine, tool0;
            ELSEIF num_msg = 2 THEN
                MoveJ Leftdown, v1500, fine, tool0;
            ELSEIF num_msg = 3 THEN
                MoveJ Forwarddown, v1500, fine, tool0;
            ELSEIF num_msg = 4 THEN
                MoveJ Rightdown, v1500, fine, tool0;
            ENDIF
            
            motor_angle := ReadMotor(1);
            TPWrite NumToStr(motor_angle, 4);
            
        ENDWHILE        


        TPWrite "closing now";
        SocketClose clientSocket;
        SocketClose mySocket;
        
    ENDPROC

    
    
ENDMODULE
