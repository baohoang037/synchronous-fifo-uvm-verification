task body();

        repeat (2)
            send_item(0, 0, 0, '0);

        for (int i = 0; i < DEPTH; i++) begin
            send_item(1,1,0,i);
        end

        send_item(1,1,0,8'hFF);

endtask
