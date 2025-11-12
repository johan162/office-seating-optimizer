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
> This will need a valid Gemini API way to work so you will need a Google Account.
> Please create a `.env.local` file with one line:
> `GEMINI_API_KEY=YOUR_API_KEY`
> Where you replace `YOUR_API_KEY` with your actual API key.
> Google offers free tier API keys that is ggod enough so it will work in this context.
> A paid subscription will get the answer faster and with much less risk of the server being
> overloaded.

### Getting your own Gemini AI `API_KEY`

To use this program you need your own Gemini AI `API_KEY`. The free version is enough 
for this application aas long as it is acceptable that from time to time you may get
a message that the server is overloaded and that you should try again. There is also a
paid tier with much higher limits meaning you get the answer faster and are very unlikely
to get a message about server overload.

Do this to get a free key:

1. Goto [https://ai.google.dev/gemini-api/docs](https://ai.google.dev/gemini-api/docs) and log-in using your Google Account
2. Click the button `Get a Gemini API Key` 

Follow the instruction and you will have get a key. Store that in a safe place. You will shortly need it.

There are basically two way you can run this program. If you are a developer you might want to¨
clone the repo continue from there. If you just want to use it as quickly as possible then getting
a container image from GitHub Container Registry is the easiest way.


### From source

YOu first need to install all Node library dependencies

`$ npm install`


**Running jte program as a developer server**
This is implemented as a React application using Node.js.  To get started on a local do the following:

Create a local file that contains your API_KEY called `env.local` in project root

```text
VITE_GEMINI_API_KEY="YOUR-API-KEY"
```

replace the placeholder text with your actual API_KEY. 

Now you can start the local dev server as so:

`$ npm start dev`

This will then start a local server and inofmration text on which port the server is available on will be printed
(usually `localhost:3000`)

**Building and running a local container**

This is easiest done with the included Makefile in two steps

1. Build the container: `make c-build`
2. Run container `GEMINI_API_KEY="YOUR-API-KEY" make c-run`

YOu can also define an environment variable in for example `.zshenv` 

```
export GEMINI_API_KEY="YOUR-API-KEY"
```

Close the terminal and open a new terminal. The run

```
make c-run
```

and everyhing will work fine.


The container is setup to serve the the local site at `localhost:8080`

**eploying a production server**

Therne is a third way built-in to node and that is to run the optimized compiled version
directly using node. This is simalr to starting a dev server but instead uing the
pre-compiled optimized typescript that is created by the npm build command as such:

`$ npm run build`
`$ npm run preview`

This will run a local optimized app. The port served will be displayed as info message.

### Run directly from pre-built container

(we assume you have docker or Podman installed)

To download the pre-built container from `ghcr.io/johan162/office-seating-optimizer:latest` using Podman, run the following command:

```bash
podman pull ghcr.io/johan162/office-seating-optimizer:latest
```

Then, to run the container using the included Makefile, set your API key as an environment variable for example in
`.zshenv` as 

```
export GEMINI_API_KEY="YOUR-API-KEY"
```

Then source the `.zshenv` file of just close and open up a new shell. The container can now be run as


```bash
podman run -d -p 8080:80 -e VITE_API_KEY=$(GEMINI_API_KEY) --name office-optimizer office-seating-optimizer:latest
```

This will start the application and serve it at `localhost:8080`.


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




