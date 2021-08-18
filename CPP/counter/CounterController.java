package com.example.demo.counter;

import com.example.demo.counter.Counter;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;


@RestController
public class CounterController {
    @GetMapping(value = "/counter")
    public String getCounter(){
        Counter counter = new Counter();
        return counter.getCounter() + " requests were fulfilled";
    }
}