# Seating AI Optimization

![Version](https://img.shields.io/badge/version-0.0.1-brightgreen.svg)


## Introduction

This solves the following organization seating optimization problem using Google Gemini AI:

1. The organization demands attendece in office *D* days during weekdays
2. The organization has *N* seats available (which are in general less than the number of people in the organization)
3. All staff is part of one team
4. All members in the same team are in the offce the same days
5. Each team can select on day they prefer not to be in the office

The solution is then a combination of teams and days that adhere to the above constraints.

## Getting started

> [!NOTE]
> This will need a valid Gemini API way to work. 
> Please create a `.env.local` file with one line:
> `GEMINI_API_KEY=YOUR_API_KEY`
> Where you replace `YOUR_API_KEY` with your actual API key.
> Google offers free tier API keys that is ggod enough so it will work in this context.
> A paid subscription will get the answer faster and with much less risk of the server being
> overloaded.


This is implemented as a React application using Node.js.  To get started on a local do the following:

`$ npm install`

To then start the local server do:

`$ npm start dev`

This will then start a local server on `localhost:3000`

## Deploying a production server

`$ npm run build`
`$ npm run preview`

This will run a local model. To make a proper deployment copy the content on the `dist` directory
to a static direcory on your web-server.

## Implementation

The implementation is a small React based UI wrapper 
on top of Google Gemini AI call. The program does not by itself implement any optimization algorithm.

The detailed prompt that is sent to the Google Gemini AI server is as follows:

```
You are an expert in combinatorial optimization. Your task is to solve an office space scheduling problem.

Here are the constraints and goals:
- Total available office seats (N): ${seats}
- Required number of office days per week for each team (D): ${daysInOffice}
- Your algorithm's maximum search depth (M): ${maxDepth}
- Number of solutions to return: ${numSolutions}

Here are the teams to schedule:
${teamDetails}

Your task is to assign exactly ${daysInOffice} weekdays (Monday-Friday) to each team, subject to the following rules:

1. All members of a single team must be in the office on the same days.
2. The total number of people (sum of team sizes) in the office on any given day cannot exceed the available seats (N).
3. The primary optimization goal is to MINIMIZE the number of teams assigned to their "Least Favorable Day". A team is penalized if one of its assigned office days is its least favorable day. The total count of such teams is the solution's "score". A lower score is better.

Simulate a search for the best solutions using a method analogous to dynamic programming with backtracking. Explore the solution space up to the specified search depth (M) to find the globally optimal solutions.

Return the top ${numSolutions} best solutions you find, sorted by the score (lowest first). For each solution, provide the team assignments, the final score, and the calculated daily headcount.
Provide your answer in the specified JSON format.
```




