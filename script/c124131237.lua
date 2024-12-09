--파이고라 마아트라스
local s,id=GetID()
function s.initial_effect(c)
	c:EnableReviveLimit()
	Fusion.AddProcMixN(c,true,true,aux.FilterBoolFunctionEx(Card.IsSetCard,0x822),3)
    --①: 이 카드를 융합 소환했을 경우에 발동할 수 있다. 자신의 묘지에서 "파이고라" 몬스터 1장을 특수 소환한다. 이 턴에, 자신은 레벨을 가진 암석족 몬스터밖에 특수 소환할 수 없다.
    local e1=Effect.CreateEffect(c)
    e1:SetDescription(aux.Stringid(id,0))
     e1:SetCategory(CATEGORY_SPECIAL_SUMMON)
     e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
     e1:SetProperty(EFFECT_FLAG_DELAY+EFFECT_FLAG_DAMAGE_STEP)
     e1:SetCode(EVENT_SPSUMMON_SUCCESS)
     e1:SetCountLimit(1,id)
     e1:SetCondition(function(e) return e:GetHandler():IsSummonType(SUMMON_TYPE_FUSION) end)
     e1:SetTarget(s.rmtg)
     e1:SetOperation(s.rmop)
     c:RegisterEffect(e1)
    	--atk
        local e3=Effect.CreateEffect(c)
        e3:SetType(EFFECT_TYPE_FIELD)
        e3:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
        e3:SetCode(EFFECT_CANNOT_ACTIVATE)
        e3:SetTargetRange(0,1)
        e3:SetRange(LOCATION_MZONE)
        e3:SetCondition(s.cona)
        e3:SetValue(1)
        c:RegisterEffect(e3)
        --def
        local e2=Effect.CreateEffect(c)
        e2:SetDescription(aux.Stringid(id,2))
        e2:SetCategory(CATEGORY_TOGRAVE)
        e2:SetType(EFFECT_TYPE_IGNITION)
        e2:SetProperty(EFFECT_FLAG_NO_TURN_RESET)
        e2:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
        e2:SetRange(LOCATION_MZONE)
        e2:SetCountLimit(1)
        e2:SetCondition(s.cond)
        e2:SetCost(s.btcost)
        e2:SetTarget(s.tgtg)
        e2:SetOperation(s.tgop)
        c:RegisterEffect(e2)
end
function s.spfilter2(c,e,tp)
	return c:IsSetCard(0x822) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
end
function s.rmtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.GetLocationCount(tp,LOCATION_MZONE)>0
		and Duel.IsExistingMatchingCard(s.spfilter2,tp,LOCATION_GRAVE,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_GRAVE)
end
function s.rmop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter2,tp,LOCATION_GRAVE,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
	-- Cannot Special Summon from the Extra Deck, except Xyz Monsters
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
function s.splimit(e,c,sump,sumtype,sumpos,targetp,se)
	return not (c:HasLevel() and c:IsRace(RACE_ROCK))
end
function s.cona(e)
	return e:GetHandler():IsAttackPos() and Duel.IsTurnPlayer(e:GetHandlerPlayer())
end
function s.cond(e)
	return e:GetHandler():IsDefensePos()
end
function s.immval(e,te)
    return te:GetOwnerPlayer()==1-e:GetHandlerPlayer() 
end
function s.btcfilter(c)
	return c:IsMonster() and c:IsRace(RACE_ROCK) and c:IsType(TYPE_FUSION) and c:IsAbleToRemoveAsCost() and aux.SpElimFilter(c,true)
end
function s.btcost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.btcfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,nil)
		and e:GetHandler():GetFlagEffect(id)==0 end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_REMOVE)
	local g=Duel.SelectMatchingCard(tp,s.btcfilter,tp,LOCATION_MZONE+LOCATION_GRAVE,0,1,1,nil)
	Duel.Remove(g,POS_FACEUP,REASON_COST)
	e:GetHandler():RegisterFlagEffect(id,RESET_EVENT+RESETS_STANDARD+RESET_PHASE+PHASE_DAMAGE,0,1)
end
function s.tgfilter(c)
	return not c:IsRace(RACE_ROCK) and c:IsAbleToGrave()
end
function s.tgtg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,1,nil) end
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SetOperationInfo(0,CATEGORY_TOGRAVE,g,#g,0,0)
end
function s.tgop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.tgfilter,tp,LOCATION_MZONE,LOCATION_MZONE,nil)
	Duel.SendtoGrave(g,REASON_EFFECT)
end
