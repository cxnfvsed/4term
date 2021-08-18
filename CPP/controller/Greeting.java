package com.example.demo.controller;

public class Greeting {
    private int year;
    private String t1 = "leap";
    private String t2 ="not leap";

    public Greeting()
    {

    }

    public Greeting(int y) {
        this.year = y;
    }

    public int getYear() {
        return year;
    }


    public String getContent() {
        if(this.year%100==0 && this.year%400==0)
            return t1;
            //t1 = "leap";
        else if(this.year%4==0 && this.year%100>0)
            return t1;
            //t1 = "leap";
        else if(this.year%100 ==0)
            return t2;
            //t2= "not leap";
        else return t2;//t2 = "not leap";
    }

}