package com.example.demo.counter;

public class Counter extends Thread { //nasleduem Threads
    private static Integer counter =0; //counter
   //sync - выполняется одним потоком одновременно
    public synchronized void incCounter(){
        if(this.isRunnable())
        {
            counter++;
        }
        else{
            this.start(); //запуск потока
            counter++;
        }
    }

    public synchronized Integer getCounter(){ //ретурн счтетчика
                return counter;
    }

    @Override
    public synchronized void start(){
        super.start();
    }

    public synchronized boolean isRunnable(){
        return super.isAlive() && !super.isInterrupted(); //выполнятся и не прерван
    }
}