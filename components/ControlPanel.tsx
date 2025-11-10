
import React from 'react';
import { UploadIcon, SparklesIcon, LoadingSpinner } from './icons';

interface ControlPanelProps {
  onFileChange: (event: React.ChangeEvent<HTMLInputElement>) => void;
  onSolve: () => void;
  isSolving: boolean;
  fileLoaded: boolean;
  seats: number;
  setSeats: (value: number) => void;
  daysInOffice: number;
  setDaysInOffice: (value: number) => void;
  maxDepth: number;
  setMaxDepth: (value: number) => void;
  numSolutions: number;
  setNumSolutions: (value: number) => void;
}

const ControlInput: React.FC<{ label: string; value: number; onChange: (val: number) => void; min?: number, max?: number, helpText: string }> = ({ label, value, onChange, min = 1, max, helpText }) => (
    <div>
        <label className="block text-sm font-medium text-slate-300">{label}</label>
        <input
            type="number"
            value={value}
            min={min}
            max={max}
            onChange={(e) => onChange(parseInt(e.target.value, 10))}
            className="mt-1 block w-full bg-slate-700 border border-slate-600 rounded-md shadow-sm py-2 px-3 text-white focus:outline-none focus:ring-indigo-500 focus:border-indigo-500 sm:text-sm"
        />
        <p className="mt-1 text-xs text-slate-400">{helpText}</p>
    </div>
);


export const ControlPanel: React.FC<ControlPanelProps> = ({
  onFileChange,
  onSolve,
  isSolving,
  fileLoaded,
  seats,
  setSeats,
  daysInOffice,
  setDaysInOffice,
  maxDepth,
  setMaxDepth,
  numSolutions,
  setNumSolutions
}) => {
  return (
    <div className="bg-slate-800/50 backdrop-blur-sm p-6 rounded-lg shadow-lg border border-slate-700">
      <h2 className="text-xl font-bold text-white mb-4">Configuration</h2>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-6">
        
        <div className="lg:col-span-1">
          <label htmlFor="file-upload" className="relative cursor-pointer bg-indigo-600 hover:bg-indigo-700 text-white font-bold py-2 px-4 rounded-md inline-flex items-center justify-center w-full h-full transition-colors duration-200">
            <UploadIcon />
            <span>{fileLoaded ? 'CSV Loaded' : 'Upload CSV'}</span>
          </label>
          <input id="file-upload" name="file-upload" type="file" className="sr-only" accept=".csv" onChange={onFileChange} />
          <p className="mt-1 text-xs text-slate-400 text-center">Format: Name,Team</p>
        </div>

        <ControlInput label="Available Seats (N)" value={seats} onChange={setSeats} helpText="Total seats in the office." />
        <ControlInput label="Days in Office (D)" value={daysInOffice} max={5} onChange={setDaysInOffice} helpText="Required days per week." />
        <ControlInput label="Max Search Depth (M)" value={maxDepth} onChange={setMaxDepth} helpText="Algorithm complexity." />
        <ControlInput label="# Solutions to Show" value={numSolutions} max={5} onChange={setNumSolutions} helpText="Top solutions to display." />

      </div>
      <div className="mt-6">
        <button
          onClick={onSolve}
          disabled={!fileLoaded || isSolving}
          className="w-full flex items-center justify-center px-6 py-3 border border-transparent text-base font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 disabled:bg-slate-500 disabled:cursor-not-allowed focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-offset-slate-900 focus:ring-indigo-500 transition-all duration-200"
        >
          {isSolving ? <LoadingSpinner /> : <SparklesIcon />}
          {isSolving ? 'Finding Optimal Solution...' : 'Optimize Schedule'}
        </button>
      </div>
    </div>
  );
};
