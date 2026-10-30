task body();


        repeat (2)
        send_item(0, 0, 0, '0);
        send_item(1, 1, 0, 8'hA5);
        send_item(1, 1, 0, 8'hB6);
        send_item(1, 0, 1, '0);
        send_item(1, 0, 1, '0);
        send_item(1, 0, 0, '0);

    endtask