--올마이티 셀레스티얼 타이탄-창조자 이터니티
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Synchro.AddProcedure(c,nil,2,2,Synchro.NonTunerEx(s.matfilter),1,1)
	c:AddMustBeSynchroSummoned()
	Pendulum.AddProcedure(c,false)
	--Cannot be destroyed by effects
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_SINGLE)
	e1:SetProperty(EFFECT_FLAG_SINGLE_RANGE)
	e1:SetRange(LOCATION_MZONE)
	e1:SetCode(EFFECT_INDESTRUCTABLE_EFFECT)
	e1:SetValue(1)
	c:RegisterEffect(e1)
	--Change a monster effect activated by the opponent
	local e4=Effect.CreateEffect(c)
	e4:SetDescription(aux.Stringid(id,0))
	e4:SetType(EFFECT_TYPE_QUICK_O)
	e4:SetCode(EVENT_CHAINING)
	e4:SetRange(LOCATION_MZONE)
	e4:SetCountLimit(1,id)
	e4:SetCondition(function(e,tp,eg,ep,ev,re,r,rp) return rp==1-tp and re:IsMonsterEffect() end)
	e4:SetCost(s.cost)
	e4:SetCondition(s.chcon)
	e4:SetTarget(s.chngtg)
	e4:SetOperation(s.chngop)
	c:RegisterEffect(e4)
end
s.listed_series={0xc02}
s.synchro_nt_required=1
function s.matfilter(c,val,scard,sumtype,tp)
	return c:IsRace(RACE_FAIRY,scard,sumtype,tp) and c:IsType(TYPE_SYNCHRO,scard,sumtype,tp)
end

function s.cost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.CheckLPCost(tp,500) end
	Duel.PayLPCost(tp,1000)
end
function s.fairyfilter(c)
	return c:IsRace(RACE_FAIRY) and c:IsMonster() and (c:IsFaceup() or not c:IsOnField())
end
function s.chcon(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	return rp==1-tp and (re:IsMonsterEffect() or ((rc:IsSpell() or rc:IsTrap()) and re:IsHasType(EFFECT_TYPE_ACTIVATE)))
end
function s.chngtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.fairyfilter,tp,LOCATION_GRAVE,0,1,e:GetHandler()) end
end
function s.chngop(e,tp,eg,ep,ev,re,r,rp)
	local g=Group.CreateGroup()
	Duel.ChangeTargetCard(ev,g)
	Duel.ChangeChainOperation(ev,s.repop)
end
function s.repop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,1-tp,HINTMSG_SPSUMMON)
	local sg=Duel.SelectMatchingCard(1-tp,aux.NecroValleyFilter(s.fairyfilter),tp,0,LOCATION_GRAVE,1,1,nil,e,1-tp)
		local tc=sg:GetFirst() 
		if tc then
			Duel.SpecialSummon(tc,0,1-tp,1-tp,false,false,POS_FACEUP)
		end
end
