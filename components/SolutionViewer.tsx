
import React from 'react';
import { Solution, Person, Weekday, WEEKDAYS } from '../types';

interface SolutionViewerProps {
    solutions: Solution[];
    people: Person[];
    seats: number;
}

const SolutionCard: React.FC<{ solution: Solution; people: Person[]; index: number, seats: number }> = ({ solution, people, index, seats }) => {
    const sortedPeople = [...people].sort((a, b) => {
        if (a.team < b.team) return -1;
        if (a.team > b.team) return 1;
        return a.name.localeCompare(b.name);
    });

    const assignmentsMap = new Map<string, Weekday[]>(
        solution.assignments.map(a => [a.teamName, a.days])
    );
    
    return (
        <div className="bg-slate-800/50 backdrop-blur-sm p-6 rounded-lg shadow-lg border border-slate-700">
            <div className="flex justify-between items-center mb-4">
                <h3 className="text-xl font-bold text-white">Solution #{index + 1}</h3>
                <div className="text-right">
                    <p className="font-semibold text-indigo-400">Score: {solution.score}</p>
                    <p className="text-xs text-slate-400">(Teams on least favorable day)</p>
                </div>
            </div>

            <div className="overflow-x-auto">
                <table className="min-w-full divide-y divide-slate-700">
                    <thead className="bg-slate-800">
                        <tr>
                            <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Team</th>
                            <th className="px-4 py-3 text-left text-xs font-medium text-slate-300 uppercase tracking-wider">Person</th>
                            {WEEKDAYS.map(day => (
                                <th key={day} className="px-2 py-3 text-center text-xs font-medium text-slate-300 uppercase tracking-wider">{day.substring(0,3)}</th>
                            ))}
                        </tr>
                    </thead>
                    <tbody className="bg-slate-900/50 divide-y divide-slate-800">
                        {sortedPeople.map((person, pIndex) => {
                            const personDays = assignmentsMap.get(person.team) || [];
                            return (
                                <tr key={`${person.name}-${pIndex}`} className="hover:bg-slate-700/50">
                                    <td className="px-4 py-2 whitespace-nowrap text-sm text-slate-300">{person.team}</td>
                                    <td className="px-4 py-2 whitespace-nowrap text-sm font-medium text-white">{person.name}</td>
                                    {WEEKDAYS.map(day => (
                                        <td key={day} className="px-2 py-2 text-center">
                                            <div className={`w-6 h-6 rounded mx-auto ${personDays.includes(day) ? 'bg-green-500' : 'bg-slate-700'}`}></div>
                                        </td>
                                    ))}
                                </tr>
                            )
                        })}
                    </tbody>
                     <tfoot className="bg-slate-800 border-t-2 border-slate-600">
                        <tr>
                            <td colSpan={2} className="px-4 py-3 text-left text-sm font-medium text-slate-300">Daily Headcount</td>
                            {WEEKDAYS.map(day => {
                                const count = solution.dailyHeadcount[day as keyof typeof solution.dailyHeadcount];
                                const usage = count / seats;
                                let colorClass = 'text-green-400';
                                if (usage > 0.85) colorClass = 'text-yellow-400';
                                if (usage >= 1.0) colorClass = 'text-red-500';

                                return (
                                    <td key={day} className={`px-2 py-3 text-center text-sm font-bold ${colorClass}`}>
                                        {count}
                                    </td>
                                )
                            })}
                        </tr>
                    </tfoot>
                </table>
            </div>
        </div>
    );
};


export const SolutionViewer: React.FC<SolutionViewerProps> = ({ solutions, people, seats }) => {
    if (solutions.length === 0) {
        return null;
    }

    return (
        <div className="mt-8">
            <h2 className="text-2xl font-bold text-white mb-4">Optimal Schedules Found</h2>
            <div className="space-y-6">
                {solutions.map((solution, index) => (
                    <SolutionCard key={index} solution={solution} people={people} index={index} seats={seats} />
                ))}
            </div>
        </div>
    );
};
