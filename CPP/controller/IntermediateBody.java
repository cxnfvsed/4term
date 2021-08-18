package com.example.demo.controller;
//sending form to Post Mapping
public class IntermediateBody {
    private String year;

    public IntermediateBody() {
    }

    public IntermediateBody(String year){
        this.year=year;
    }

    public void setYear(String year) {
        this.year = year;
    }

    public String getYear(){
        return year;
    }
}