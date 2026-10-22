--스크랩 패밀리어
local s,id=GetID()
local CARD_SCRAP_WYVERN=47363932
function s.initial_effect(c)
	c:EnableReviveLimit()
	--링크 소환: 레벨 4 이하의 "스크랩" 몬스터 1장
	Link.AddProcedure(c,s.matfilter,1,1)
	--①: 특수 소환했을 경우, 패 / 덱의 "스크랩" 카드를 3장까지 묘지로 보내고 발동
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,0))
	e1:SetCategory(CATEGORY_DESTROY)
	e1:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e1:SetProperty(EFFECT_FLAG_DELAY)
	e1:SetCode(EVENT_SPSUMMON_SUCCESS)
	e1:SetCountLimit(1,id)
	e1:SetCost(s.descost)
	e1:SetTarget(s.destg)
	e1:SetOperation(s.desop)
	c:RegisterEffect(e1)
	--②: 효과로 파괴되었을 경우, 엑스트라 덱에서 "스크랩 와이번" 특수 소환
	local e2=Effect.CreateEffect(c)
	e2:SetDescription(aux.Stringid(id,1))
	e2:SetCategory(CATEGORY_SPECIAL_SUMMON)
	e2:SetType(EFFECT_TYPE_SINGLE+EFFECT_TYPE_TRIGGER_O)
	e2:SetProperty(EFFECT_FLAG_DELAY)
	e2:SetCode(EVENT_DESTROYED)
	e2:SetCountLimit(1,{id,1})
	e2:SetCondition(s.spcon)
	e2:SetTarget(s.sptg)
	e2:SetOperation(s.spop)
	c:RegisterEffect(e2)
end
s.listed_series={0x24}
s.listed_names={CARD_SCRAP_WYVERN}

function s.matfilter(c,lc,sumtype,tp)
	return c:IsSetCard(0x24,lc,sumtype,tp) and c:IsLevelBelow(4)
end

--① 코스트: 패 / 덱의 "스크랩" 카드 1~3장을 묘지로
function s.costfilter(c)
	return c:IsSetCard(0x24) and c:IsAbleToGraveAsCost()
end
function s.descost(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.costfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,nil) end
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_TOGRAVE)
	local g=Duel.SelectMatchingCard(tp,s.costfilter,tp,LOCATION_HAND|LOCATION_DECK,0,1,3,nil)
	Duel.SendtoGrave(g,REASON_COST)
end
function s.destg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(nil,tp,LOCATION_ONFIELD,0,1,nil) end
	Duel.SetOperationInfo(0,CATEGORY_DESTROY,nil,1,tp,LOCATION_ONFIELD)
end
function s.desop(e,tp,eg,ep,ev,re,r,rp)
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_DESTROY)
	local g=Duel.SelectMatchingCard(tp,nil,tp,LOCATION_ONFIELD,0,1,1,nil)
	if #g>0 then
		Duel.HintSelection(g)
		Duel.Destroy(g,REASON_EFFECT)
	end
end

--② 효과로 파괴되었을 경우
function s.spcon(e,tp,eg,ep,ev,re,r,rp)
	return (r&REASON_EFFECT)~=0
end
function s.spfilter(c,e,tp)
	return c:IsCode(CARD_SCRAP_WYVERN) and c:IsCanBeSpecialSummoned(e,0,tp,false,false)
		and Duel.GetLocationCountFromEx(tp,tp,nil,c)>0
end
function s.sptg(e,tp,eg,ep,ev,re,r,rp,chk)
	if chk==0 then return Duel.IsExistingMatchingCard(s.spfilter,tp,LOCATION_EXTRA,0,1,nil,e,tp) end
	Duel.SetOperationInfo(0,CATEGORY_SPECIAL_SUMMON,nil,1,tp,LOCATION_EXTRA)
end
function s.spop(e,tp,eg,ep,ev,re,r,rp)
	local c=e:GetHandler()
	Duel.Hint(HINT_SELECTMSG,tp,HINTMSG_SPSUMMON)
	local g=Duel.SelectMatchingCard(tp,s.spfilter,tp,LOCATION_EXTRA,0,1,1,nil,e,tp)
	if #g>0 then
		Duel.SpecialSummon(g,0,tp,tp,false,false,POS_FACEUP)
	end
	--이 듀얼 중에 적용 (중복 등록 방지)
	if Duel.GetFlagEffect(tp,id)>0 then return end
	Duel.RegisterFlagEffect(tp,id,0,0,1)
	--클라이언트 힌트 표시용
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(id)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(1,0)
	Duel.RegisterEffect(e1,tp)
	--원래의 카드명에 "스크랩"을 포함하는 자신 필드의 싱크로 몬스터를 감시해서
	--그 몬스터의 기동 효과를 "상대 턴에 발동할 수 있는 퀵 효과"로 복제해 준다
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e2:SetCode(EVENT_ADJUST)
	e2:SetOperation(s.adjop)
	Duel.RegisterEffect(e2,tp)
end

function s.scrapsyfilter(c)
	return c:IsFaceup() and c:IsOriginalSetCard(0x24) and c:IsOriginalType(TYPE_SYNCHRO)
		and c:GetFlagEffect(id)==0
end
function s.adjop(e,tp,eg,ep,ev,re,r,rp)
	local g=Duel.GetMatchingGroup(s.scrapsyfilter,tp,LOCATION_MZONE,0,nil)
	for tc in g:Iter() do
		tc:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
		s.addquick(tc,tp)
	end
end
--대상 몬스터의 initial_effect를 다시 실행하되, 기동 효과만 골라
--"상대 턴에만 발동할 수 있는 퀵 효과" 복제본으로 등록한다 (나머지 효과는 등록하지 않음)
function s.addquick(tc,tp)
	local mt=tc:GetMetatable()
	if not (mt and mt.initial_effect) then return end
	local reg=Card.RegisterEffect
	Card.RegisterEffect=function(card,eff,...)
		if card==tc and eff:IsHasType(EFFECT_TYPE_IGNITION) then
			local qe=eff:Clone()
			qe:SetType(EFFECT_TYPE_QUICK_O)
			qe:SetCode(EVENT_FREE_CHAIN)
			qe:SetHintTiming(0,TIMINGS_CHECK_MONSTER_E)
			local con=eff:GetCondition()
			qe:SetCondition(function(e,tp2,...)
				local h=e:GetHandler()
				return h:IsControler(tp) and Duel.IsTurnPlayer(1-tp)
					and Duel.GetFlagEffect(tp,id)>0
					and (not con or con(e,tp2,...))
			end)
			qe:SetReset(RESET_EVENT|RESETS_STANDARD)
			return reg(card,qe,...)
		end
		return 0
	end
	local ok,err=pcall(mt.initial_effect,tc)
	Card.RegisterEffect=reg
	if not ok then Debug.Message(err) end
end
