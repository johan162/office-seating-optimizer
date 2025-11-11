
import { GoogleGenAI, Type } from "@google/genai";
import { Team, Solution } from '../types';

const solutionSchema = {
    type: Type.OBJECT,
    properties: {
        solutions: {
            type: Type.ARRAY,
            description: "An array of the best solutions found, sorted by score.",
            items: {
                type: Type.OBJECT,
                properties: {
                    assignments: {
                        type: Type.ARRAY,
                        description: "The day assignments for each team.",
                        items: {
                            type: Type.OBJECT,
                            properties: {
                                teamName: { type: Type.STRING },
                                days: {
                                    type: Type.ARRAY,
                                    items: { type: Type.STRING }
                                }
                            },
                             required: ['teamName', 'days'],
                        }
                    },
                    score: {
                        type: Type.INTEGER,
                        description: "The optimization score: the number of teams assigned to their least favorable day. Lower is better."
                    },
                    dailyHeadcount: {
                        type: Type.OBJECT,
                        description: "The total number of people in the office for each weekday.",
                        properties: {
                            Monday: { type: Type.INTEGER },
                            Tuesday: { type: Type.INTEGER },
                            Wednesday: { type: Type.INTEGER },
                            Thursday: { type: Type.INTEGER },
                            Friday: { type: Type.INTEGER }
                        },
                        required: ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday'],
                    }
                },
                required: ['assignments', 'score', 'dailyHeadcount'],
            }
        }
    },
    required: ['solutions'],
};


export const solveOptimizationProblem = async (
    teams: Team[],
    seats: number,
    daysInOffice: number,
    maxDepth: number,
    numSolutions: number
): Promise<Solution[]> => {
    // if (!import.meta.env.VITE_API_KEY) {
    //     throw new Error("API_KEY environment variable not set");
    // }

    console.log("Calling Gemini API with the following parameters:");
    console.log(`- Seats: ${seats}`);
    console.log(`- Days in Office: ${daysInOffice}`);
    console.log(`- Max Depth: ${maxDepth}`);
    console.log(`- Number of Solutions: ${numSolutions}`);
    console.log(" - API Key: " + import.meta.env.VITE_GEMINI_API_KEY?.substring(0, 5) + "****");
    
    const ai = new GoogleGenAI({ apiKey: import.meta.env.VITE_GEMINI_API_KEY });

    const teamDetails = teams.map(t => 
        `- Team: "${t.name}", Size: ${t.size}, Least Favorable Day: ${t.leastFavorableDay || 'None'}`
    ).join('\n');

    const prompt = `
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
3. The primary optimization goal is to MINIMIZE the number of people assigned to their "Least Favorable Day". A team is penalized if one of its assigned office days is its least favorable day. The total count of number of people in teams assigned to their least favorable days is the solution's "score". A lower score is better.

Simulate a search for the best solutions using a method analogous to dynamic programming with backtracking. Explore the solution space up to the specified search depth (M) to find the globally optimal solutions.

Return the top ${numSolutions} best solutions you find, sorted by the score (lowest first). For each solution, provide the team assignments, the final score, and the calculated daily headcount.
Provide your answer in the specified JSON format.
`;

    try {
        const response = await ai.models.generateContent({
            model: "gemini-2.5-pro",
            contents: prompt,
            config: {
                responseMimeType: "application/json",
                responseSchema: solutionSchema,
            },
        });
        
        const jsonText = response.text.trim();
        const result = JSON.parse(jsonText);

        if (result && result.solutions) {
            return result.solutions as Solution[];
        } else {
            console.error("Unexpected JSON structure:", result);
            throw new Error("Failed to parse solutions from Gemini response.");
        }

    } catch (error) {
        console.error("Error calling Gemini API:", error);

        // Check for specific error types that indicate server-side issues
        if (error instanceof Error && (error.message.includes('503') || /overloaded|internal issue/i.test(error.message))) {
            throw new Error("The model is currently overloaded or experiencing internal issues. Please try again in a few moments.");
        }

        throw new Error("The AI model failed to generate a valid solution. Please check your inputs and try again.");
    }
};
