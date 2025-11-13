
import React, { useState, useCallback } from 'react';
import { Person, Team, Weekday, Solution } from './types';
import { ControlPanel } from './components/ControlPanel';
import { TeamConfiguration } from './components/TeamConfiguration';
import { SolutionViewer } from './components/SolutionViewer';
import { solveOptimizationProblem } from './services/geminiService';
// FIX: Import `LoadingSpinner` component from `components/icons`.
import { LoadingSpinner } from './components/icons';

const version = '1.0.2';

const App: React.FC = () => {
    const [people, setPeople] = useState<Person[]>([]);
    const [teams, setTeams] = useState<Team[]>([]);
    const [solutions, setSolutions] = useState<Solution[]>([]);
    
    const [seats, setSeats] = useState<number>(50);
    const [daysInOffice, setDaysInOffice] = useState<number>(3);
    const [maxDepth, setMaxDepth] = useState<number>(10);
    const [numSolutions, setNumSolutions] = useState<number>(1);

    const [isSolving, setIsSolving] = useState<boolean>(false);
    const [error, setError] = useState<string | null>(null);
    const [fileLoaded, setFileLoaded] = useState<boolean>(false);

    const handleFileChange = (event: React.ChangeEvent<HTMLInputElement>) => {
        const file = event.target.files?.[0];
        if (!file) return;

        const reader = new FileReader();
        reader.onload = (e) => {
            const text = e.target?.result as string;
            try {
                const parsedPeople: Person[] = text.split('\n')
                    .map(line => line.trim())
                    .filter(line => line.includes(','))
                    .map(line => {
                        const [name, team] = line.split(',').map(s => s.trim());
                        if (!name || !team) throw new Error(`Invalid line: ${line}`);
                        return { name, team };
                    });
                
                setPeople(parsedPeople);
                
                const teamsMap = new Map<string, Person[]>();
                parsedPeople.forEach(person => {
                    if (!teamsMap.has(person.team)) {
                        teamsMap.set(person.team, []);
                    }
                    teamsMap.get(person.team)?.push(person);
                });

                const parsedTeams: Team[] = Array.from(teamsMap.entries()).map(([name, members]) => ({
                    name,
                    members,
                    size: members.length,
                    leastFavorableDay: null
                }));
                
                setTeams(parsedTeams);
                setFileLoaded(true);
                setError(null);
                setSolutions([]); // Clear previous solutions on new file upload
            } catch (err) {
                setError("Failed to parse CSV file. Please ensure it's in 'Name,Team' format with no header.");
                setFileLoaded(false);
            }
        };
        reader.readAsText(file);
    };

    const handleUpdateTeam = useCallback((teamName: string, leastFavorableDay: Weekday | null) => {
        setTeams(prevTeams => prevTeams.map(team => 
            team.name === teamName ? { ...team, leastFavorableDay } : team
        ));
    }, []);

    const handleSolve = async () => {
        setIsSolving(true);
        setError(null);
        setSolutions([]);

        try {
            const result = await solveOptimizationProblem(
                teams,
                seats,
                daysInOffice,
                maxDepth,
                numSolutions
            );
            
            if(result.length === 0){
              setError("The model couldn't find any valid solutions for the given constraints. Try adjusting the number of seats or days in office.");
            }
            setSolutions(result);
        } catch (err) {
            setError(err instanceof Error ? err.message : "An unknown error occurred.");
        } finally {
            setIsSolving(false);
        }
    };


    return (
        <div className="min-h-screen bg-slate-900 bg-gradient-to-br from-slate-900 to-indigo-900/30 font-sans">
            <div className="container mx-auto p-4 md:p-8">
                <header className="text-center mb-8">
                    <h1 className="text-4xl md:text-5xl font-bold text-white tracking-tight">Office Seating Optimizer</h1>
                    <p className="mt-2 text-lg text-indigo-300">Intelligent scheduling powered by Gemini AI</p>
                    <p className="mt-1 text-sm text-gray-600 italic">v{version} © 2025 Johan Persson</p>
                </header>
                
                <main>
                    <ControlPanel
                        onFileChange={handleFileChange}
                        onSolve={handleSolve}
                        isSolving={isSolving}
                        fileLoaded={fileLoaded}
                        seats={seats}
                        setSeats={setSeats}
                        daysInOffice={daysInOffice}
                        setDaysInOffice={setDaysInOffice}
                        maxDepth={maxDepth}
                        setMaxDepth={setMaxDepth}
                        numSolutions={numSolutions}
                        setNumSolutions={setNumSolutions}
                    />

                    {error && (
                        <div className="mt-6 bg-red-500/20 border border-red-500 text-red-300 px-4 py-3 rounded-lg relative" role="alert">
                            <strong className="font-bold">Error: </strong>
                            <span className="block sm:inline">{error}</span>
                        </div>
                    )}
                    
                    {!fileLoaded && !isSolving && (
                         <div className="text-center py-16 px-6 bg-slate-800/30 mt-8 rounded-lg border border-dashed border-slate-600">
                            <h2 className="text-xl font-medium text-slate-300">Get Started</h2>
                            <p className="mt-1 text-slate-400">Upload a CSV file of your team members to begin the optimization process.</p>
                        </div>
                    )}

                    <TeamConfiguration teams={teams} onUpdateTeam={handleUpdateTeam} />
                    
                    {isSolving && (
                         <div className="text-center py-16 px-6 bg-slate-800/30 mt-8 rounded-lg">
                            <div className="flex justify-center items-center mb-4">
                               <LoadingSpinner />
                            </div>
                            <h2 className="text-xl font-medium text-slate-200 animate-pulse">Analyzing possibilities...</h2>
                            <p className="mt-1 text-slate-400">This might take a moment as the AI finds the best schedule.</p>
                        </div>
                    )}
                    
                    <SolutionViewer solutions={solutions} people={people} seats={seats} />
                </main>
            </div>
        </div>
    );
};

export default App;