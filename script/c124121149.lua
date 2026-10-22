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
	--글로벌: "스크랩" 싱크로 몬스터의 기동 효과 / 퀵 버전 발동 기록 (1턴에 1번 공유용)
	aux.GlobalCheck(s,function()
		s.used={}
		local ge=Effect.GlobalEffect()
		ge:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
		ge:SetCode(EVENT_CHAINING)
		ge:SetOperation(s.chainop)
		Duel.RegisterEffect(ge,0)
	end)
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
	--퀵 버전이 붙은 몬스터의 원래 기동 효과는 발동할 수 없다 (아르스=마그나의 aux.NOT(citrinitascon)에 해당)
	local e2=Effect.CreateEffect(c)
	e2:SetType(EFFECT_TYPE_FIELD)
	e2:SetCode(EFFECT_CANNOT_ACTIVATE)
	e2:SetProperty(EFFECT_FLAG_PLAYER_TARGET)
	e2:SetTargetRange(1,0)
	e2:SetValue(s.aclimit)
	Duel.RegisterEffect(e2,tp)
	--원래의 카드명에 "스크랩"을 포함하는 자신 필드의 싱크로 몬스터를 감시해서 퀵 버전을 붙인다
	local e3=Effect.CreateEffect(c)
	e3:SetType(EFFECT_TYPE_FIELD+EFFECT_TYPE_CONTINUOUS)
	e3:SetCode(EVENT_ADJUST)
	e3:SetOperation(s.adjop)
	Duel.RegisterEffect(e3,tp)
end
function s.aclimit(e,re,tp)
	local rc=re:GetHandler()
	return re:IsHasType(EFFECT_TYPE_IGNITION) and rc:IsLocation(LOCATION_MZONE)
		and rc:GetFlagEffect(id)>0
end

--발동 기록: 카드 + 처리 함수 단위로, 같은 턴 / 같은 필드 존재 중에만 유효
--(카드가 필드를 떠났다 돌아오면 FieldID가 바뀌어 기록이 초기화된다 = 일반 턴제와 같은 동작)
function s.getrec(c)
	local t=s.used[c]
	local fid,turn=c:GetFieldID(),Duel.GetTurnCount()
	if not t or t.fid~=fid or t.turn~=turn then
		t={fid=fid,turn=turn,ops={}}
		s.used[c]=t
	end
	return t
end
function s.chainop(e,tp,eg,ep,ev,re,r,rp)
	local rc=re:GetHandler()
	if not (rc:IsLocation(LOCATION_MZONE) and rc:IsOriginalSetCard(0x24) and rc:IsOriginalType(TYPE_SYNCHRO)) then return end
	if not (re:IsHasType(EFFECT_TYPE_IGNITION) or re:IsHasType(EFFECT_TYPE_QUICK_O)) then return end
	local op=re:GetOperation()
	if op then s.getrec(rc).ops[op]=true end
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
--대상 몬스터의 initial_effect를 다시 실행해서 기동 효과의 부품(조건/코스트/대상/처리)만 가져와
--자신 턴 / 상대 턴 모두 발동할 수 있는 퀵 효과를 만든다.
--원래 효과의 카운트 리밋은 쓰지 않고, "1턴에 1번"은 발동 기록(s.used)으로 관리한다.
--퀵 버전 적용 전에 원래 기동 효과를 이미 쓴 턴이라면 그 턴엔 퀵 버전도 쓸 수 없다.
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
		local con,op=eff:GetCondition(),eff:GetOperation()
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
				and not s.getrec(h).ops[op]
				and (not con or con(e,ctp,...))
		end)
		qe:SetCost(eff:GetCost())
		qe:SetTarget(eff:GetTarget())
		qe:SetOperation(op)
		qe:SetReset(RESET_EVENT|RESETS_STANDARD)
		reg(tc,qe)
	end
end
