
import React from 'react';
import { Team, Weekday, WEEKDAYS } from '../types';

interface TeamConfigurationProps {
  teams: Team[];
  onUpdateTeam: (teamName: string, leastFavorableDay: Weekday | null) => void;
}

const TeamCard: React.FC<{ team: Team; onUpdateTeam: (teamName: string, leastFavorableDay: Weekday | null) => void; }> = ({ team, onUpdateTeam }) => (
    <div className="bg-slate-800 p-4 rounded-lg border border-slate-700 flex flex-col sm:flex-row justify-between items-center space-y-3 sm:space-y-0">
        <div>
            <p className="font-bold text-white">{team.name}</p>
            <p className="text-sm text-slate-400">{team.size} member{team.size > 1 ? 's' : ''}</p>
        </div>
        <div className="w-full sm:w-auto">
            <label className="text-sm font-medium text-slate-300 mr-2">Least Favorable Day</label>
            <select
                value={team.leastFavorableDay || ''}
                onChange={(e) => onUpdateTeam(team.name, e.target.value as Weekday || null)}
                className="bg-slate-700 border border-slate-600 rounded-md shadow-sm py-2 px-3 text-white focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm w-full"
            >
                <option value="">None</option>
                {WEEKDAYS.map(day => <option key={day} value={day}>{day}</option>)}
            </select>
        </div>
    </div>
);

export const TeamConfiguration: React.FC<TeamConfigurationProps> = ({ teams, onUpdateTeam }) => {
    if (teams.length === 0) {
        return null;
    }

    return (
        <div className="mt-8">
            <h2 className="text-2xl font-bold text-white mb-4">Team Preferences</h2>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                {teams.map(team => (
                    <TeamCard key={team.name} team={team} onUpdateTeam={onUpdateTeam} />
                ))}
            </div>
        </div>
    );
};
