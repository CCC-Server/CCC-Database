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
	--이 듀얼 중에 적용 (이미 적용 중이면 중복 등록하지 않음)
	if Duel.IsPlayerAffectedByEffect(tp,id) then return end
	--적용 표시 겸 클라이언트 힌트 (리셋 없음 = 듀얼 종료까지 유지)
	local e1=Effect.CreateEffect(c)
	e1:SetDescription(aux.Stringid(id,2))
	e1:SetType(EFFECT_TYPE_FIELD)
	e1:SetCode(id)
	e1:SetProperty(EFFECT_FLAG_PLAYER_TARGET+EFFECT_FLAG_CLIENT_HINT)
	e1:SetTargetRange(1,0)
	Duel.RegisterEffect(e1,tp)
	--원래의 카드명에 "스크랩"을 포함하는 자신 필드의 싱크로 몬스터를 감시해서
	--그 몬스터의 기동 효과를 "자신 / 상대 턴에 발동할 수 있는 퀵 효과"로 추가해 준다
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
		--필드를 떠나거나 뒷면이 되면 플래그가 지워지고, 다시 나오면 새로 붙는다
		tc:RegisterFlagEffect(id,RESET_EVENT|RESETS_STANDARD,0,1)
		s.addquick(tc,tp)
	end
end
--대상 몬스터의 initial_effect를 다시 실행해서 기동 효과의 "부품"(대상/코스트/처리 등)만 가져오고,
--그걸로 새 퀵 효과를 만든다. 원래 효과의 카운트 리밋은 복사하지 않고,
--"1턴에 1번"은 카드에 붙이는 플래그(매 턴 엔드 페이즈에 리셋)로 따로 관리한다.
--퀵 버전은 자신 턴 / 상대 턴 모두 발동할 수 있다.
local quick_count=0
function s.addquick(tc,tp)
	local mt=tc:GetMetatable()
	if not (mt and mt.initial_effect) then return end
	local reg=Card.RegisterEffect
	local list={}
	Card.RegisterEffect=function(card,eff,...)
		if card==tc and eff:IsHasType(EFFECT_TYPE_IGNITION) then
			table.insert(list,eff)
		end
		return 0 --실제 등록은 하지 않음
	end
	local ok,err=pcall(mt.initial_effect,tc)
	Card.RegisterEffect=reg
	if not ok then Debug.Message(err) return end
	for _,eff in ipairs(list) do
		quick_count=quick_count+1
		local flag=id+quick_count --효과마다 별도의 "1턴에 1번" 플래그
		local con,cost=eff:GetCondition(),eff:GetCost()
		local qe=Effect.CreateEffect(tc)
		qe:SetDescription(eff:GetDescription())
		qe:SetCategory(eff:GetCategory())
		qe:SetProperty(eff:GetProperty())
		qe:SetType(EFFECT_TYPE_QUICK_O)
		qe:SetCode(EVENT_FREE_CHAIN)
		qe:SetRange(LOCATION_MZONE)
		qe:SetHintTiming(0,TIMING_STANDBY_PHASE|TIMING_MAIN_END|TIMINGS_CHECK_MONSTER_E)
		qe:SetLabel(eff:GetLabel())
		qe:SetLabelObject(eff:GetLabelObject())
		qe:SetCondition(function(e,ctp,...)
			local h=e:GetHandler()
			return h:IsControler(tp) and Duel.IsPlayerAffectedByEffect(tp,id)
				and h:GetFlagEffect(flag)==0
				and (not con or con(e,ctp,...))
		end)
		qe:SetCost(function(e,ctp,eg,ep,ev,re,r,rp,chk)
			if chk==0 then return not cost or cost(e,ctp,eg,ep,ev,re,r,rp,0) end
			--발동한 시점에 "이 턴 사용함" 표시 (무효가 되어도 사용한 것으로 취급)
			e:GetHandler():RegisterFlagEffect(flag,RESET_EVENT|RESETS_STANDARD|RESET_PHASE|PHASE_END,0,1)
			if cost then cost(e,ctp,eg,ep,ev,re,r,rp,chk) end
		end)
		qe:SetTarget(eff:GetTarget())
		qe:SetOperation(eff:GetOperation())
		qe:SetReset(RESET_EVENT|RESETS_STANDARD)
		reg(tc,qe)
	end
end
