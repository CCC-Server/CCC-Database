--파이고라 퓨전
local s,id=GetID()
function s.initial_effect(c)
	local e1=Fusion.CreateSummonEff(c,aux.FilterBoolFunction(Card.IsSetCard,0x822),nil,nil,nil,nil,s.stage2)
local tg=e1:GetTarget()
e1:SetTarget(function(e,tp,eg,ep,ev,re,r,rp,chk)
				if chk==0 then
					return tg(e,tp,eg,ep,ev,re,r,rp,chk)
				end
				tg(e,tp,eg,ep,ev,re,r,rp,chk)
				if e:IsHasType(EFFECT_TYPE_ACTIVATE) then
					Duel.SetChainLimit(aux.FALSE)
				end
			end)
c:RegisterEffect(e1)
local e2=Effect.CreateEffect(c)
e2:SetDescription(aux.Stringid(id,1))
e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
e2:SetType(EFFECT_TYPE_IGNITION)
e2:SetRange(LOCATION_GRAVE)
e2:SetProperty(EFFECT_FLAG_CARD_TARGET)
e2:SetCost(aux.bfgcost)
e2:SetTarget(s.sptg)
e2:SetOperation(s.spop)
c:RegisterEffect(e2)
end
function s.stage2(e,tc,tp,sg,chk)
if chk==1 then
	tc:RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD,0,1,e:GetHandler():GetCardID())
end
end
function s.mgfilter(c,e,tp,fusc,mg)
return c:IsControler(tp) and c:IsLocation(LOCATION_GRAVE)
	and (c:GetReason()&0x40008)==0x40008 and c:GetReasonCard()==fusc
	and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
	and fusc:CheckFusionMaterial(mg,c,PLAYER_NONE|FUSPROC_NOTFUSION)
end
function s.spfilter(c,e,tp)
if c:IsFaceup() and c:GetFlagEffect(id)~=0 and c:GetFlagEffectLabel(id)==e:GetHandler():GetCardID() then
	local mg=c:GetMaterial()
	local ct=#mg
	return ct>0 and ct<=Duel.GetLocationCount(tp,LOCATION_MZONE)
		and mg:FilterCount(s.mgfilter,nil,e,tp,c,mg)==ct
		and (not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) or ct<=1)
else return false end
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk,chkc)
if chkc then return chkc:IsLocation(LOCATION_MZONE) and s.spfilter(chkc,e,tp) end
if chk==0 then return Duel.IsExistingTarget(s.spfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil,e,tp) end
Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_FACEUP)
Duel.SelectTarget(tp,s.spfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,1,nil,e,tp)
Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,2,tp,LOCATION_GRAVE)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
local c=e:GetHandler()
local tc=Duel.GetFirstTarget()
if not tc or not tc:IsRelateToEffect(e) then return end
local mg=tc:GetMaterial()
local ct=#mg
if ct>0 and ct<=Duel.GetLocationCount(tp,LOCATION_MZONE)
	and mg:FilterCount(s.mgfilter,nil,e,tp,tc,mg)==ct
	and not Duel.IsPlayerAffectedByEffect(tp,CARD_BLUEEYES_SPIRIT) then
	local sc=mg:GetFirst()
	for sc in aux.Next(mg) do
		if Duel.SpecialSummonStep(sc,0,tp,tp,false,false,POS_FACEUP) then
			local e1=Effect.CreateEffect(e:GetHandler())
			e1:SetDescription(aux.Stringid(id,2))
			e1:SetType(EFFECT_TYPE_FIELD)
			e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
			e1:SetCode(EFFECT_CANNOT_SPECIAL_SUMMON)
			e1:SetTargetRange(1,0)
			e1:SetTarget(s.splimit)
			e1:SetReset(RESET_PHASE+PHASE_END)
			Duel.RegisterEffect(e1,tp)
		end
	end
	Duel.SpecialSummonComplete()
end
end
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:HasLevel() and c:IsRace(RACE_ROCK))
end